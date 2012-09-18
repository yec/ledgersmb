BEGIN;
\i Base.sql


INSERT INTO chart (description, charttype, category, accno)
VALUES ('TEST testing 1', 'A', 'A', '00001');

INSERT INTO chart (description, charttype, category, accno)
VALUES ('TEST testing 2', 'A', 'A', '00002');

INSERT INTO entity_credit_account (id, meta_number, entity_id, entity_class, ar_ap_account_id) 
values (-100, 'test1', -100, 1, -1000);

INSERT INTO ap (invnumber, netamount, amount, entity_credit_account, id, curr) 
VALUES ('TEST', '0', '0', -100, -100, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount)
VALUES (-100, currval('account_id_seq')::int, '0');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP 1', 'A', 'L', '00003', 'AP');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP 2', 'A', 'L', '00004', 'AP');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR 1', 'A', 'A', '00005', 'AR');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR 2', 'A', 'A', '00006', 'AR');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR PAID 1', 'A', 'A', '00007', 'AR_paid');

insert into account_link_description(description, summary, custom)
values ('AR_paid1', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR PAID 2', 'A', 'A', '00008', 'AR_paid1');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR PAID 3', 'A', 'A', '00009', 'IC_tax:AR_paid');

insert into account_link_description(description, summary, custom)
values ('AR_p', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AR PAID 4 INVALID', 'A', 'A', '00010', 'AR_p');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP PAID 1', 'A', 'A', '00011', 'AP_paid');

insert into account_link_description(description, summary, custom)
values ('AP_paid1', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP PAID 2', 'A', 'A', '00012', 'AP_paid1');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP PAID 3', 'A', 'A', '00013', 'IC_tax:AP_paid');

insert into account_link_description(description, summary, custom)
values ('AP_p', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP PAID 4 INVALID', 'A', 'A', '00014', 'AP_p');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 1', 'A', 'A', '00015', 'AP_overpayment');

insert into account_link_description(description, summary, custom)
values ('AP_overpayment1', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 2', 'A', 'A', '00016', 'AP_overpayment1');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 3', 'A', 'A', '00017', 'IC_tax:AP_overpayment');

insert into account_link_description(description, summary, custom)
values ('AP_overp', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 4 INVALID', 'A', 'A', '00018', 'AP_overp');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 1', 'A', 'A', '00019', 'AR_overpayment');

insert into account_link_description(description, summary, custom)
values ('AR_overpayment1', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 2', 'A', 'A', '00020', 'AR_overpayment1');

INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 3', 'A', 'A', '00021', 'IC_tax:AR_overpayment');

insert into account_link_description(description, summary, custom)
values ('AR_overp', false, true);
INSERT INTO chart (description, charttype, category, accno, link)
VALUES ('TEST AP Overpayment 4 INVALID', 'A', 'A', '00022', 'AR_overp');

INSERT INTO test_result(test_name, success)
VALUES ('Accounts created', currval('account_id_seq') is not null);

INSERT INTO test_result(test_name, success)
VALUES ('Chart 1 is orphaned', account_has_transactions((select id from chart where description = 'TEST testing 1')) is false);

INSERT INTO test_result(test_name, success)
VALUES ('Chart 2 is not orphaned', account_has_transactions((select id from chart where accno = '00002')) is true);

INSERT INTO test_result(test_name, success)
SELECT 'All Test Accounts Exist', count(*) = 23 FROM chart_list_all() 
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'List AR Cash Test Accounts', count(*) = 3 FROM chart_list_cash(2) 
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'List AP Cash Test Accounts', count(*) = 3 FROM chart_list_cash(1) 
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'List AP Overpayment Accts', count(*) = 3 FROM chart_list_overpayment(1)
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'List AR Overpayment Accts', count(*) = 3 FROM chart_list_overpayment(2)
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'Test AP Accounts Are Found', count(*) = 2 FROM chart_get_ar_ap(1)
where accno like '0%' AND description LIKE 'TEST%';

INSERT INTO test_result(test_name, success)
SELECT 'Test AR Accounts Are Found', count(*) = 2 FROM chart_get_ar_ap(2)
where accno like '0%' AND description LIKE 'TEST%';

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
