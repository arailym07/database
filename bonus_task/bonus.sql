

-- task 1

create or replace procedure process_transfer(
       from_acc text,
       to_acc text,
       amount numeric,
       currency text,
       description text
)

language plpgsql
as $$
declare
       from_id int,
       to_id int,
       rate_numeric = 1,
       balance numeric,
       cust_status text,
       lim_kzt numeric,
       today_sum numeric,
       amount_kzt numeric;
begin
       select account_id, balance, customer_id
       into from_id, balance, to_id
       from accounts
       where acc_num = from_acc and is_active = true
       for update;

       if not found then
          raise exception ' sender account not found';
       end if;

       select account_id
       into to_id
       from accounts
       where acc_num = to_acc and is_active = true
       for update;

       if not found then
          raise exception 'receiver account not found';
        end if;


       -- status cust
       select status, daily_lim_kzt
       into cust_status, lim_kzt
       from customers
       where customer_id = ( select customer_id from accounts where acc_num = from_acc);

       if cust_status <> 'active' then
          raise exception 'customer is not active';
       end if;


       -- balance
       if balance < amount then
          raise exception 'not enough money';
        end if;


       -- today sum
        select coalesce(sum(amount_kzt), 0)
        into today_sum
        from transactions
        where from_acc_id = from_id
        and created_at::date = current_date;


       -- currency
       if currency <> 'kzt' then
          select rate into rate
          from exchange_rates
          where from_currency = currency and to_currency = 'kzt'
          order by valid_from desc
          limit 1;
       end if;


       savepoint start_transfer;

       update accounts
       set balance = balance - amount
       where acc_id = from_id;

       update accounts
       set balance = balance + amount
       where acc_id = to_id;


       -- transactions
       insert into transactions(from_acc_id, to_acc_id, amount, currency, eschange_rate, amount_kzt, type, status, created_at, description)
       values (from_id, to_id, amount, currency, rate, amount_kzt, 'transfer', 'completed', now(), description );

       --log
       insert into audit_log(table_name, action, new_values, changed_at)
       values('transactions', 'insert', build_object('amount', amount), now());


exception when others then
       rollback to savepoint start_transfer;
       insert into audit_log(table_num, action, old_values, changed_at)
       values ('transfer_error', 'error', build_object('error')., now());
       raise;
end;
$$;




-- task 2

--view1
create or replace view customer_balance_sum as
       select
           c.customer_id,
           c.full_name,
           a.acc_number,
           a.currency,
           a.balance,
           (a.balance *
            ( select rate from exchange_rates
              where from_currency = a.currency and to_currency = 'kzt'
              order by valid_from desc limit 1)
            ) as balance_kzt,
            c.daily_limit_kzt,
            (coalesce(
            select sum(amount_kzt) from transactions
            where from_acc_id = a.acc_id
            and created_at :: date = current_date), 0
            ) / c.daily_limit_kzt) * 100 as limit_usage,
            rank() over(order by a.balance desc) as ranking
       from customers c
       join accounts a on a.customer_id = c.customer_id;


--view2
create or replace view daily_transaction_report as
       select
           created_at:: date as day,
       type,
       count(*) as tx_cnt,
       sum(amount_kzt) as total_amount,
       avg(amount_kzt) as avg_amount,
       sum(sum(amount_kzt)) over(
       order by created_at::date
       ) as running_total
       from transactions
       group by day, type
       order by day;


--view3
create view suspicious_activity_view
with (security_barrier = true)
as
select *
from transactions t
where
    t.amount_kzt > 5000000
or (
    select count(*) from transactions t2
    where t2.from_acc_id = t.from_acc_id
    and t2.created_at > t.created_at - interval '1 hour'
    ) > 10
or (
    select count(*) from transactions t3
    where t3.from_acc_id = t.from_acc_id
        and t3.created_at between t.created_at - interval '1 minute' and t.created_at
    ) > 1;



-- task 3

-- b tree
create index idx_acc_num on accounts(acct_number);

--hash
create index idx_acc_currency_hash on accounts using hash(currency);

-- gin
create index idx_audit_log on audit_log using gin(new_values);

-- partial
create index idx_active_acc on accounts(acc_number)
where is_active = true;

-- expression
create index idx_cust_email_lower on customers(lower(email));



-- task 4
create or replace procedure process_salary(
       company_acc text,
       payments jsonb
)
language plpgsql
as $$
declare
       company_id int;
       total numeric = 0;
       ok int = 0;
       fail int = 0;
       item jsonb;
begin
      perform pg_advisory_lock(999);

      select acc_id into company_id
      from accounts where acc_number = company_acc
      for update;

      if not found then
         raise exception 'company account not found';
      end if;

      --sum
      for item in select * from array_elements(payments)
      loop
            total := total + (item -> 'amount') numeric;
      end loop;

      --balance
      if (select balance from accounts where acc_id = company_id) < total then
            raise exception 'not enough money for batch';
      end if;

      --
      for item in select * from array_elements(payments)
      loop
            savepoint one_payment;

            begin
            call process_transfer(
                company_acc,
                (select account_num
                from accounts a
                join customers c on c.customer_id = a.customer_id
                where c.in = item -> 'in'
                limit 1),
                (item -> 'amount') numeric, 'kzt', item -> 'description'
            );
            ok := ok + 1;

            exception when others then
             rollback to savepoint pay_start;
             fail := fail + 1;
            end;

      end loop;

      raise notice 'done. success. failed', ok, fail;

      perform pg_advisory_unlock(1000);

    end;
    $$;