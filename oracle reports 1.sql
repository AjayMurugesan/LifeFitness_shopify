/* Formatted on 15-04-2022 14:11:19 (QP5 v5.115.810.9015) */
SELECT customer_id,
       REPLACE(REPLACE(REPLACE(abc.cust_name_inv,
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') customer_name,
       REPLACE(REPLACE(REPLACE(abc.cust_no_inv,
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') customer_number,
       REPLACE(REPLACE(REPLACE(nvl(abc.cust_type,
                                   '-'),
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') customer_class,
       REPLACE(REPLACE(REPLACE(abc.invnum,
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') invoice_no,
       REPLACE(REPLACE(REPLACE(abc.inv_currency,
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') currency_code,
       REPLACE(REPLACE(REPLACE(abc.ps_exchange_rate_inv,
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') exchange_rate,
       REPLACE(REPLACE(REPLACE(decode(abc.class_inv,
                                      'PMT',
                                      'Payment',
                                      abc.invoice_type_inv),
                               chr(9),
                               ''),
                       chr(10),
                       ''),
               chr(13),
               '') trx_type, -- 57198
       --    abc.class_inv trx_type,
       (SELECT rtt.NAME FROM ra_terms_tl rtt WHERE rtt.term_id = abc.term_id and rtt.language = 'US') payment_term,  --Mantis - FIN-1671
       abc.gl_date_inv inv_date,
       abc.due_date_inv,
       nvl((SELECT DISTINCT ps.preship_invoice_number
              FROM atl_exim_pre_ship_line_pak_dtl pp,
                   ra_customer_trx_all            rcta,
                   atl_exim_pre_ship_hdr_all      ps
             WHERE pp.delivery_id = interface_header_attribute3 AND
                   ps.preship_hdr_id = pp.preship_hdr_id AND
                   to_char(trx_number) = to_char(abc.invnum)
                   and rcta.ORG_ID=abc.org_id
                   and rcta.CUSTOMER_TRX_ID = abc.customer_id),
            '-') -------added by TXIS mantis no - 62689
       -- (SELECT REPLACE(REPLACE(REPLACE(nvl(rcta.attribute1,'-'),chr(9),''),chr(10),''),chr(13),'') Atl_ex_inv_no
       /*FROM
                          ra_customer_trx_all            rcta
                     ,     ar_payment_schedules_all     apsa
                     where
                     1=1
                     and  rcta.customer_trx_id         =     apsa.customer_trx_id
                     and  apsa.payment_schedule_id     =     abc.payment_sched_id_inv
                     )*/ excise_inv_no,
                      nvl((SELECT listagg(DISTINCT to_char(ps.post_shipment_invoice_no),
                          ',') within
            GROUP(
            ORDER BY ps.post_shipment_invoice_no) t
from xxcus.atl_exim_postship_hdr_all ps,xxcus.atl_exim_postship_preship_all pps,ra_customer_trx_all rt
where ps.post_shipment_header_id =  pps.post_shipment_header_id
--and pps.trx_id = rt.CUSTOMER_TRX_ID
and to_char(pps.trx_number)=to_char(abc.invnum)
and ps.ORG_ID=abc.org_id and ps.CUSTOMER_ID=abc.customer_id),'-')post_shipment_invoice_no,
       nvl((SELECT listagg(DISTINCT to_char(ps.shipping_bill_no),
                          ',') within
            GROUP(
            ORDER BY ps.shipping_bill_no) t
             FROM atl_exim_pre_ship_line_pak_dtl pp,
                  ra_customer_trx_all            rcta,
                  atl_exim_pre_ship_hdr_all      ps,
                  ar_payment_schedules_all       apsa
            WHERE pp.delivery_id = rcta.interface_header_attribute3 AND
                  ps.preship_hdr_id = pp.preship_hdr_id AND
                  to_char(rcta.trx_number) = to_char(abc.invnum) AND
                  rcta.customer_trx_id = apsa.customer_trx_id AND
                  apsa.payment_schedule_id = abc.payment_sched_id_inv),
           '-') shipping_bill_no, --mantis no-63104
       nvl((SELECT listagg(DISTINCT eh.bl_awb_no,
                          ',') within
            GROUP(
            ORDER BY eh.bl_awb_no) t
             FROM atl_exim_postship_hdr_all  eh,
                  atl_exim_postship_item_dtl ed,
                  ra_customer_trx_all        rcta,
                  ar_payment_schedules_all   apsa
            WHERE eh.post_shipment_header_id = ed.post_shipment_header_id AND
                  ed.delivery_id = rcta.interface_header_attribute3 AND
                  to_char(rcta.trx_number) = to_char(abc.invnum) AND
                  rcta.customer_trx_id = apsa.customer_trx_id AND
                  apsa.payment_schedule_id = abc.payment_sched_id_inv),
           '-') bl_no, --mantis no-63104     
       (SELECT listagg(tax_invoice_num,
                       ',') within
         GROUP(
         ORDER BY pay_id ASC)
          FROM (SELECT DISTINCT j.tax_invoice_num,
                                rh.payment_schedule_id pay_id
                  FROM jai_tax_lines j, ar_payment_schedules_all rh
                 WHERE rh.customer_trx_id = j.trx_id AND
                       j.tax_event_class_code = 'SALES_TRANSACTION' AND --j.event_type_code IN ('INV_COMPLETE','CM_COMPLETE','DM_COMPLETE')  AND
                       j.event_class_code IN
                       ('INVOICE', 'CREDIT_MEMO', 'DEBIT_MEMO') AND -- Mantis No - 58940
                       j.org_id = rh.org_id AND rh.gl_date >= '01-JUL-2017' AND
                       j.tax_invoice_num IS NOT NULL
                UNION
                SELECT DISTINCT j.tax_invoice_num,
                                ar.payment_schedule_id pay_id
                  FROM ar_payment_schedules_all ar, jai_tax_lines j
                 WHERE ar.cash_receipt_id = j.trx_id AND
                       j.tax_event_class_code = 'SALES_TRANSACTION' AND
                       j.event_type_code = 'RECEIPT_CREATE' AND
                       ar.org_id = j.org_id AND ar.gl_date >= '01-JUL-2017' AND
                       j.tax_invoice_num IS NOT NULL)
         WHERE pay_id = abc.payment_sched_id_inv) gst_no,
       SUM(nvl(abc.amt_due_remaining_inv,
               0)) tot_outstndng,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                1,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_1,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                2,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_2,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                3,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_3,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                4,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_4,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                5,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_5,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                6,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_6,
       SUM(atl_aging_bucket_amt(ATUL 15 7B,
                                7,
                                SYSDATE,
                                abc.due_date_inv,
                                nvl(abc.amt_due_remaining_inv,
                                    0))) bucket_amt_7,
       (SELECT h.NAME
          FROM hr_operating_units h
         WHERE h.organization_id = abc.org_id) ou_name,
       SUM(decode(sign(to_date(SYSDATE,
                               'DD-MM-YY') --DD-MON-YY
                       - to_date(abc.due_date_inv,
                                 'DD-MM-YY')), --DD-MON-YY
                  1,
                  nvl(abc.amt_due_remaining_inv,
                      0),
                  0)) tot_overdue_amt,
         CASE
         WHEN REPLACE(REPLACE(REPLACE(abc.inv_currency,
                                      chr(9),
                                      ''),
                              chr(10),
                              ''),
                      chr(13),
                      '') <> 'INR' THEN
          SUM(decode(sign(to_date(SYSDATE,
                                  'DD-MM-YY') --DD-MON-YY
                          - to_date(abc.due_date_inv,
                                    'DD-MM-YY')),
                     1,
                     nvl(abc.amt_due_remaining_inv,
                         0),
                     0)) / nvl(abc.ps_exchange_rate_inv,
                               1)
         ELSE
          0
       END AS fc_overdue_amt,
       CASE
         WHEN REPLACE(REPLACE(REPLACE(abc.inv_currency,
                                      chr(9),
                                      ''),
                              chr(10),
                              ''),
                      chr(13),
                      '') <> 'INR' THEN
          SUM(nvl(abc.amt_due_remaining_inv,
                  0)) / nvl(abc.ps_exchange_rate_inv,
                            1)
         ELSE
          0
       END AS fc_outstanding_amt,
       nvl((SELECT DISTINCT listagg((hcpa.currency_code || ' ' ||
                                   hcpa.overall_credit_limit),
                                   ',') within
            GROUP(
            ORDER BY apsa.payment_schedule_id ASC) cr_limit
             FROM hz_cust_acct_sites_all   hca,
                  hz_cust_site_uses_all    hcs,
                  hz_customer_profiles     hcp,
                  hz_cust_profile_amts     hcpa,
                  ar_payment_schedules_all apsa
            WHERE 1 = 1 AND hca.cust_acct_site_id = hcs.cust_acct_site_id AND
                  hcs.site_use_code = 'BILL_TO' AND hca.status = 'A' AND
                  hca.cust_account_id = hcp.cust_account_id AND
                  hcs.site_use_id = hcp.site_use_id AND
                  hcpa.cust_account_profile_id =
                  hcp.cust_account_profile_id AND
                  hca.cust_account_id = apsa.customer_id AND
                  hcs.site_use_id = apsa.customer_site_use_id AND
                  hca.org_id = apsa.org_id AND
                  apsa.payment_schedule_id = abc.payment_sched_id_inv),
           (SELECT DISTINCT listagg((hcpa.currency_code || ' ' ||
                                    hcpa.overall_credit_limit),
                                    ',') within
             GROUP(
             ORDER BY abc.customer_id ASC) cr_limit
              FROM hz_cust_profile_amts hcpa
             WHERE 1 = 1 AND hcpa.cust_account_id = abc.customer_id AND
                   hcpa.site_use_id IS NULL)) credit_limit,
       (SELECT rcta.attribute11 bank_ref_no
          FROM ar_payment_schedules_all apsa, ra_customer_trx_all rcta
         WHERE 1 = 1 AND rcta.customer_trx_id = apsa.customer_trx_id AND
               apsa.payment_schedule_id = abc.payment_sched_id_inv) bank_ref_no,
       (SELECT rcta.attribute12 bank_ref_date
          FROM ar_payment_schedules_all apsa, ra_customer_trx_all rcta
         WHERE 1 = 1 AND rcta.customer_trx_id = apsa.customer_trx_id AND
               apsa.payment_schedule_id = abc.payment_sched_id_inv) bank_ref_date,
       (SELECT nvl(jrre.resource_name,
                   'No Sales Person') resource_name
          FROM ar_payment_schedules_all apsa,
               ra_customer_trx_all      rcta,
               jtf_rs_salesreps         jra,
               jtf_rs_resource_extns_vl jrre
         WHERE 1 = 1 AND rcta.customer_trx_id = apsa.customer_trx_id AND
               jra.salesrep_id = rcta.primary_salesrep_id AND
               jra.org_id = rcta.org_id AND
               jra.resource_id = jrre.resource_id AND
               apsa.payment_schedule_id = abc.payment_sched_id_inv) sales_person,
       abc.company_inv pcsc,
       abc.acct natural_acct_code,
       abc.cost_center,
       (SELECT fv.description
          FROM fnd_flex_values_vl fv
         WHERE fv.flex_value_set_id = 1013709 AND
               fv.flex_value = abc.cost_center) cc_description,
       (SELECT DISTINCT nvl(d.credit_classification,
                            'Not Available') credit_classification
          FROM hz_customer_profiles d
         WHERE 1 = 1 AND d.cust_account_id = abc.customer_id AND
               d.site_use_id IS NULL) risk_category,
       (select replace(replace(replace(ra.purchase_order, chr(9), ''), chr(10), ''), chr(13), '') from      -- FIN-1553
       ra_customer_trx_all ra
       where to_char(ra.trx_number) = to_char(abc.invnum) and ra.org_id = abc.org_id and
               ra.ship_to_customer_id = abc.customer_id and ra.set_of_books_id = '2021') po_num           --FIN-1117  
                   ,abc.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                   ,abc.CREATION_DATE  --- Added By Nikita on 200324 mantis no - FIN-2325           
                   ,abc.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                   ,abc.LAST_UPDATE_DATE  --- Added By Nikita on 200324 mantis no - FIN-2325      
-------------------- addd column abc.
  FROM (
  SELECT substrb(party.party_name,
                       1,
                       50) cust_name_inv,
               cust_acct.account_number cust_no_inv,
               cust_acct.customer_class_code cust_type,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      NULL,
                      apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                       ps.org_id)) sort_field1_inv,
               apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                ps.org_id) sort_field2_inv,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      -999,
                      ps.cust_trx_type_id) inv_tid_inv,
               site.site_use_id contact_site_id_inv,
               loc.state cust_state_inv,
               loc.city cust_city_inv,
               decode(NULL,
                      NULL,
                      -1,
                      acct_site.cust_acct_site_id) addr_id_inv,
               nvl(cust_acct.cust_account_id,
                   -999) p_cust_id_inv,
               ps.payment_schedule_id payment_sched_id_inv,
               ps.class class_inv,
               ps.term_id,
               ps.due_date due_date_inv,
               amt_due_remaining_inv,
               ps.trx_number invnum,
               ps.amount_adjusted amount_adjusted_inv,
               ps.amount_applied amount_applied_inv,
               ps.amount_credited amount_credited_inv,
               ps.gl_date gl_date_inv,
               decode(ps.invoice_currency_code,
                      'INR',
                      NULL,
                      decode(ps.exchange_rate,
                             NULL,
                             '*',
                             NULL)) data_converted_inv,
               nvl(ps.exchange_rate,
                   1) ps_exchange_rate_inv,
               c.segment2 company_inv,
               c.segment4 acct,
               c.segment3 cost_center,
               to_char(NULL) cons_billing_number,
               apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                ps.org_id) invoice_type_inv,
               ps.invoice_currency_code inv_currency,
               ps.org_id org_id,
               ps.customer_id customer_id ,
               ps.CREATED_BY   ,          ----Added By Nikita on 140324 mantis no - FIN-2325 
             ps.CREATION_DATE ,    ----Added By Nikita on 200324 mantis no - FIN-2325 
              ps.LAST_UPDATED_BY ,  ----Added By Nikita on 140324 mantis no - FIN-2325 
            ps.LAST_UPDATE_DATE  ----Added By Nikita on 200324  mantis no - FIN-2325 
          FROM hz_cust_accounts cust_acct,
               hz_parties party,
               (     
               SELECT a.customer_id,
                       a.customer_site_use_id,
                       a.customer_trx_id,
                       a.payment_schedule_id,
                       a.class,
                       a.term_id,
                       SUM(a.primary_salesrep_id) primary_salesrep_id,
                       a.due_date,
                       SUM(a.amount_due_remaining) amt_due_remaining_inv,
                       a.trx_number,
                       a.amount_adjusted,
                       a.amount_applied,
                       a.amount_credited,
                       a.amount_adjusted_pending,
                       a.gl_date,
                       a.cust_trx_type_id,
                       a.org_id,
                       a.invoice_currency_code,
                       a.exchange_rate,
                       SUM(a.cons_inv_id) cons_inv_id ,
                       a.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                      , a.CREATION_DATE   ----Added By Nikita on 200324 mantis no - FIN-2325 
                      ,a.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                      ,a.LAST_UPDATE_DATE   ----Added By Nikita on 200324 mantis no - FIN-2325 
                  FROM (
                  SELECT ps.customer_id,
                               ps.customer_site_use_id,
                               ps.customer_trx_id,
                               ps.payment_schedule_id,
                               ps.class,
                               ps.term_id,
                               0 primary_salesrep_id,
                               atl_sales_recog_ar_due_date(ps.org_id,
                                                           ps.customer_id,
                                                           ps.customer_trx_id,
                                                           ps.due_date) due_date,
                               nvl(SUM(decode('Y',
                                              'Y',
                                              nvl(adj.acctd_amount,
                                                  0),
                                              adj.amount)),
                                   0) * (-1) amount_due_remaining,
                               ps.trx_number,
                               ps.amount_adjusted,
                               ps.amount_applied,
                               ps.amount_credited,
                               ps.amount_adjusted_pending,
                               ps.gl_date,
                               ps.cust_trx_type_id,
                               ps.org_id,
                               ps.invoice_currency_code,
                               nvl(ps.exchange_rate,
                                   1) exchange_rate,
                               0 cons_inv_id,
                         ( select  o.CREATED_BY                 
                            from  ar_payment_schedules_all o
                          where    o.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID ----Added By Nikita on 210324 mantis no - FIN-2325 
                          AND o.LAST_UPDATE_DATE =  (SELECT max(g.CREATION_DATE)
                                                                                               from  ar_payment_schedules_all g
                                                                                               where  g.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID)) CREATED_BY ----Added By Nikita on 210324 mantis no - FIN-2325 
                              ,(select max(n.CREATION_DATE)
                              from   ar_payment_schedules_all n 
                              where n.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID) CREATION_DATE   ----Added By Nikita on 210324 mantis no - FIN-2325 
                                ,( select  y.LAST_UPDATED_BY                 
                            from  ar_payment_schedules_all y
                          where    y.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID
                          and     y.LAST_UPDATE_DATE = (SELECT max(u.LAST_UPDATE_DATE) --- correct n ny
                                                                                               from  ar_payment_schedules_all u
                                                                                               where  u.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID)) LAST_UPDATED_BY   ----Added By Nikita on 210324 mantis no - FIN-2325 
                             ,(select max(m.LAST_UPDATE_DATE)
                               from ar_payment_schedules_all  m 
                               where  m.PAYMENT_SCHEDULE_ID = adj.PAYMENT_SCHEDULE_ID) LAST_UPDATE_DATE  ----Added By Nikita on 210324   --------- change mantis no - FIN-2325 
                          FROM ar_payment_schedules_all ps,
                               ar_adjustments_all       adj
                         WHERE ps.gl_date <= to_date(SYSDATE,
                                                     'DD-MM-YY') --DD-MON-YY
                               AND ps.customer_id > 0 AND
                               ps.gl_date_closed >
                               to_date(SYSDATE,
                                       'DD-MM-YY') --DD-MON-YY
                               AND -- ps.org_id = p_org_id AND
                               decode(upper(NULL),
                                      NULL,
                                      ps.invoice_currency_code,
                                      upper(NULL)) = ps.invoice_currency_code AND
                               adj.payment_schedule_id =
                               ps.payment_schedule_id AND adj.status = 'A' AND
                               adj.gl_date > to_date(SYSDATE,
                                                     'DD-MM-YY') --DD-MON-YY
                         GROUP BY ps.customer_id,
                                  ps.customer_site_use_id,
                                  ps.customer_trx_id,
                                  ps.class,
                                  ps.term_id,
                                  ps.due_date,
                                  ps.trx_number,
                                  ps.amount_adjusted,
                                  ps.amount_applied,
                                  ps.amount_credited,
                                  ps.amount_adjusted_pending,
                                  ps.gl_date,
                                  ps.cust_trx_type_id,
                                  ps.org_id,
                                  ps.invoice_currency_code,
                                  nvl(ps.exchange_rate,
                                      1),
                                  ps.payment_schedule_id,
                                 ps.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                               ,ps.CREATION_DATE     ----Added By Nikita on 140324 mantis no - FIN-2325 
                               ,ps.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                              ,ps.LAST_UPDATE_DATE  ----Added By Nikita on 140324  mantis no - FIN-2325 
                              ,adj.PAYMENT_SCHEDULE_ID
                        UNION ALL
                        SELECT ps.customer_id,
                               ps.customer_site_use_id,
                               ps.customer_trx_id,
                               ps.payment_schedule_id,
                               ps.class,
                               ps.term_id,
                               0 primary_salesrep_id,
                               atl_sales_recog_ar_due_date(ps.org_id,
                                                           ps.customer_id,
                                                           ps.customer_trx_id,
                                                           ps.due_date) due_date,
                               nvl(SUM(decode('Y',
                                              'Y',
                                              (decode(ps.class,
                                                      'CM',
                                                      decode(app.application_type,
                                                             'CM',
                                                             app.acctd_amount_applied_from,
                                                             app.acctd_amount_applied_to),
                                                      app.acctd_amount_applied_to) +
                                              nvl(app.acctd_earned_discount_taken,
                                                   0) + nvl(app.acctd_unearned_discount_taken,
                                                             0)),
                                              (app.amount_applied +
                                              nvl(app.earned_discount_taken,
                                                   0) + nvl(app.unearned_discount_taken,
                                                             0))) *
                                       decode(ps.class,
                                              'CM',
                                              decode(app.application_type,
                                                     'CM',
                                                     -1,
                                                     1),
                                              1)),
                                   0) amount_due_remaining_inv,
                               ps.trx_number,
                               ps.amount_adjusted,
                               ps.amount_applied,
                               ps.amount_credited,
                               ps.amount_adjusted_pending,
                               ps.gl_date gl_date_inv,
                               ps.cust_trx_type_id,
                               ps.org_id,
                               ps.invoice_currency_code,
                               nvl(ps.exchange_rate,
                                   1) exchange_rate,
                               0 cons_inv_id ,
                               ps.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                              ,ps.CREATION_DATE     ----Added By Nikita on 140324 mantis no - FIN-2325 
                              ,ps.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                             ,ps.LAST_UPDATE_DATE  ----Added By Nikita on 140324 mantis no - FIN-2325  -------------------------- who column ps.
                          FROM ar_payment_schedules_all       ps,
                               ar_receivable_applications_all app
                         WHERE ps.gl_date <= to_date(SYSDATE,
                                                     'DD-MM-YY') --DD-MON-YY
                               AND ps.customer_id > 0 AND
                               ps.gl_date_closed >
                               to_date(SYSDATE,
                                       'DD-MM-YY') --DD-MON-YY
                               AND --   ps.org_id = p_org_id AND
                               decode(upper(NULL),
                                      NULL,
                                      ps.invoice_currency_code,
                                      upper(NULL)) = ps.invoice_currency_code AND
                               (app.applied_payment_schedule_id =
                               ps.payment_schedule_id OR
                               app.payment_schedule_id =
                               ps.payment_schedule_id) AND
                               app.status IN ('APP', 'ACTIVITY') AND
                               nvl(app.confirmed_flag,
                                   'Y') = 'Y' AND
                               app.gl_date >
                               to_date(:p_as_of_date,
                                       'DD-MON-YY')
                         GROUP BY ps.customer_id,
                                  ps.customer_site_use_id,
                                  ps.customer_trx_id,
                                  ps.class,
                                  ps.term_id,
                                  ps.due_date,
                                  ps.trx_number,
                                  ps.amount_adjusted,
                                  ps.amount_applied,
                                  ps.amount_credited,
                                  ps.amount_adjusted_pending,
                                  ps.gl_date,
                                  ps.cust_trx_type_id,
                                  ps.org_id,
                                  ps.invoice_currency_code,
                                  nvl(ps.exchange_rate,
                                      1),
                                  ps.payment_schedule_id,
                                ps.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                              ,ps.CREATION_DATE     ----Added By Nikita on 140324 mantis no - FIN-2325 
                              ,ps.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                            ,ps.LAST_UPDATE_DATE  ----Added By Nikita on 140324  mantis no - FIN-2325 
                        UNION ALL
                        SELECT ps.customer_id,
                               ps.customer_site_use_id,
                               ps.customer_trx_id,
                               ps.payment_schedule_id,
                               ps.class class_inv,
                               ps.term_id,
                               nvl(ct.primary_salesrep_id,
                                   -3) primary_salesrep_id,
                               atl_sales_recog_ar_due_date(ps.org_id,
                                                           ps.customer_id,
                                                           ps.customer_trx_id,
                                                           ps.due_date) due_date_inv,
                               decode('Y',
                                      'Y',
                                      ps.acctd_amount_due_remaining,
                                      ps.amount_due_remaining) amt_due_remaining_inv,
                               ps.trx_number,
                               ps.amount_adjusted,
                               ps.amount_applied,
                               ps.amount_credited,
                               ps.amount_adjusted_pending,
                               ps.gl_date,
                               ps.cust_trx_type_id,
                               ps.org_id,
                               ps.invoice_currency_code,
                               nvl(ps.exchange_rate,
                                   1) exchange_rate,
                               ps.cons_inv_id,
                               ct.CREATED_BY           ----Added By Nikita on 210324 mantis no - FIN-2325 
                              ,ct.CREATION_DATE       ----Added By Nikita on 210324 mantis no - FIN-2325 
                               ,ct.LAST_UPDATED_BY    ----Added By Nikita on 210324 mantis no - FIN-2325 
                             ,ct.LAST_UPDATE_DATE    ----Added By Nikita on 210324 mantis no - FIN-2325  ------------------------ add who column ps.
                          FROM ar_payment_schedules_all ps,
                               ra_customer_trx_all      ct
                         WHERE ps.gl_date <=
                               to_date(:p_as_of_date,
                                       'DD-MON-YY') AND
                               ps.gl_date_closed >
                               to_date(:p_as_of_date,
                                       'DD-MON-YY') AND --  ps.org_id = p_org_id AND
                               decode(upper(NULL),
                                      NULL,
                                      ps.invoice_currency_code,
                                      upper(NULL)) = ps.invoice_currency_code AND
                               ps.customer_trx_id = ct.customer_trx_id) a
                 GROUP BY a.customer_id,
                          a.customer_site_use_id,
                          a.customer_trx_id,
                          a.payment_schedule_id,
                          a.class,
                          a.term_id,
                          a.due_date,
                          a.trx_number,
                          a.amount_adjusted,
                          a.amount_applied,
                          a.amount_credited,
                          a.amount_adjusted_pending,
                          a.gl_date,
                          a.cust_trx_type_id,
                          a.org_id,
                          a.invoice_currency_code,
                          a.exchange_rate,
                          a.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
                         ,a.CREATION_DATE     ----Added By Nikita on 140324 mantis no - FIN-2325 
                         ,a.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
                         ,a.LAST_UPDATE_DATE  ----Added By Nikita on 140324  mantis no - FIN-2325 
                        ) ps,
   -----------------------------------------------------------ps table
               hz_cust_site_uses_all site,
               hz_cust_acct_sites_all acct_site,
               hz_party_sites party_site,
               hz_locations loc,
               ra_cust_trx_line_gl_dist_all gld,
               xla.xla_distribution_links lk,
               xla.xla_ae_lines ae,
               ar_dispute_history dh,
               gl_code_combinations c
         WHERE upper(rtrim(rpad('I',
                                1))) = 'I' AND
               ps.customer_site_use_id = site.site_use_id AND
               site.cust_acct_site_id = acct_site.cust_acct_site_id AND
               acct_site.party_site_id = party_site.party_site_id AND
               loc.location_id = party_site.location_id AND
               gld.account_class = 'REC' AND gld.latest_rec_flag = 'Y' AND
               gld.cust_trx_line_gl_dist_id =
               lk.source_distribution_id_num_1(+) AND
               lk.source_distribution_type(+) =
               'RA_CUST_TRX_LINE_GL_DIST_ALL' AND lk.application_id(+) = 222 AND
               ae.application_id(+) = 222 AND
               lk.ae_header_id = ae.ae_header_id(+) AND
               lk.ae_line_num = ae.ae_line_num(+) AND
               decode(lk.accounting_line_code,
                      '',
                      'Y',
                      'CM_EXCH_GAIN_LOSS',
                      'N',
                      'AUTO_GEN_GAIN_LOSS',
                      'N',
                      'Y') = 'Y' AND
               decode(ae.ledger_id,
                      '',
                      decode(gld.posting_control_id,
                             -3,
                             -999999,
                             gld.code_combination_id),
                      gld.set_of_books_id,
                      ae.code_combination_id,
                      -999999) = c.code_combination_id AND
               ps.payment_schedule_id = dh.payment_schedule_id(+) AND
               to_date(:p_as_of_date,
                       'DD-MON-YY') >=
               nvl(dh.start_date(+),
                   to_date(:p_as_of_date,
                           'DD-MON-YY')) AND
               to_date(:p_as_of_date,
                       'DD-MON-YY') <
               nvl(dh.end_date(+),
                   to_date(:p_as_of_date,
                           'DD-MON-YY') + 1) AND
               cust_acct.party_id = party.party_id AND
               nvl(cust_acct.customer_class_code,
                   'XX') = upper(decode(NULL,
                                        NULL,
                                        (nvl(cust_acct.customer_class_code,
                                             'XX')),
                                        NULL)) AND
               ps.customer_id = cust_acct.cust_account_id AND
               ps.customer_id = nvl(:p_cust_id,
                                    ps.customer_id) AND --  ps.customer_id in (nvl(:P_cust_id,ps.customer_id)) and
               ps.customer_trx_id = gld.customer_trx_id AND
               gld.set_of_books_id = '2021' /*24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Prameter */
               AND c.segment2 BETWEEN '1101' AND '25582'
        --  p_in_bal_segment_low and p_in_bal_segment_high
        UNION ALL
        SELECT substrb(nvl(party.party_name,
                           NULL),
                       1,
                       50) cust_name_inv,
               cust_acct.account_number cust_no_inv,
               cust_acct.customer_class_code cust_type,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      NULL,
                      initcap(NULL)),
               initcap(NULL),
               -999,
               site.site_use_id,
               loc.state cust_state_inv,
               loc.city cust_state_inv,
               decode(NULL,
                      NULL,
                      -1,
                      acct_site.cust_acct_site_id) addr_id_inv,
               nvl(cust_acct.cust_account_id,
                   -999) p_cust_id_inv,
               ps.payment_schedule_id,
               decode(app.applied_payment_schedule_id,
                      -4,
                      'CLAIM',
                      ps.class),
               ps.term_id,
               atl_sales_recog_ar_due_date(ps.org_id,
                                           ps.customer_id,
                                           ps.customer_trx_id,
                                           ps.due_date) due_date,
               decode('Y',
                      'Y',
                      nvl(-sum(app.acctd_amount_applied_from),
                          0),
                      nvl(-sum(app.amount_applied),
                          0)),
               ps.trx_number,
               ps.amount_adjusted,
               ps.amount_applied,
               ps.amount_credited,
               ps.gl_date,
               decode(ps.invoice_currency_code,
                      'INR',
                      NULL,
                      decode(ps.exchange_rate,
                             NULL,
                             '*',
                             NULL)),
               nvl(ps.exchange_rate,
                   1),
               c.segment2 company_inv,
               c.segment4 acct,
               c.segment3 cost_center,
               to_char(NULL) cons_billing_number,
               initcap(NULL),
               ps.invoice_currency_code inv_currency,
               ps.org_id org_id,
               ps.customer_id customer_id 
                , (select  o.CREATED_BY                 
                                from  ar_receivable_applications_all o
                                where    o.CASH_RECEIPT_ID = ps.CASH_RECEIPT_ID
                                AND o.Creation_Date =  (select max(g.CREATION_DATE)
                                                                          from  ar_receivable_applications_all g
                                                                          where  g.CASH_RECEIPT_ID =  ps.CASH_RECEIPT_ID )
                                                                          AND ROWNUM = 1) CREATED_BY             ----Added By Nikita on 210324 mantis no - FIN-2325 
              , (select  max(c.CREATION_DATE) 
                  from  ar_receivable_applications_all  c  --ar_payment_schedules_all  c
                  where c.CASH_RECEIPT_ID = ps.CASH_RECEIPT_ID ) CREATION_DATE    ----Added By Nikita on 200324 mantis no - FIN-2325 
              , (select q.LAST_UPDATED_BY                 
                  from  ar_receivable_applications_all q
                 where   q.CASH_RECEIPT_ID =  ps.CASH_RECEIPT_ID
                 AND q.LAST_UPDATE_DATE =  (select max(s.LAST_UPDATE_DATE)
                                                                          from  ar_receivable_applications_all s
                                                                          where  s.CASH_RECEIPT_ID =  ps.CASH_RECEIPT_ID
                                                                           )
                                                                          AND ROWNUM = 1) LAST_UPDATED_BY    ----Added By Nikita on 210324 mantis no - FIN-2325 
              , (select  max(l.LAST_UPDATE_DATE) 
                  from  ar_receivable_applications_all  l  --ar_payment_schedules_all  l
                  where l.CASH_RECEIPT_ID = ps.CASH_RECEIPT_ID ) LAST_UPDATE_DATE  ----Added By Nikita on 200324 mantis no - FIN-2325  ----------------- who column app.
          FROM hz_cust_accounts               cust_acct,
               hz_parties                     party,
               ar_payment_schedules_all       ps,
               hz_cust_site_uses_all          site,
               hz_cust_acct_sites_all         acct_site,
               hz_party_sites                 party_site,
               hz_locations                   loc,
               ar_receivable_applications_all app,
               gl_code_combinations           c,
               --24-APR-2023|EY|ATUL ROLLOUT CHANGES| TABLE ADDED 
               ar_cash_receipts_all acr
         WHERE app.gl_date <= to_date(:p_as_of_date,
                                      'DD-MON-YY') AND
               upper(rtrim(rpad('I',
                                1))) = 'I' AND ps.trx_number IS NOT NULL AND
               ps.customer_id = cust_acct.cust_account_id(+) AND
               cust_acct.party_id = party.party_id(+) AND
               ps.cash_receipt_id = app.cash_receipt_id AND
               app.code_combination_id = c.code_combination_id AND
               app.status IN ('ACC', 'UNAPP', 'UNID', 'OTHER ACC') AND
               nvl(app.confirmed_flag,
                   'Y') = 'Y' AND
               ps.customer_site_use_id = site.site_use_id(+) AND
               site.cust_acct_site_id = acct_site.cust_acct_site_id(+) AND
               acct_site.party_site_id = party_site.party_site_id(+) AND
               loc.location_id(+) = party_site.location_id AND
               ps.gl_date_closed > to_date(:p_as_of_date,
                                           'DD-MON-YY') AND
               ((app.reversal_gl_date IS NOT NULL AND
               ps.gl_date <= to_date(:p_as_of_date,
                                       'DD-MON-YY')) OR
               app.reversal_gl_date IS NULL) AND
               decode(upper(NULL),
                      NULL,
                      ps.invoice_currency_code,
                      upper(NULL)) = ps.invoice_currency_code AND
               nvl(ps.receipt_confirmed_flag,
                   'Y') = 'Y' AND -- ps.customer_id IN (:P_cust_id) AND
               ps.customer_id = nvl(:p_cust_id,
                                    ps.customer_id) AND
               nvl(cust_acct.customer_class_code,
                   'XX') = upper(decode(NULL,
                                        NULL,
                                        (nvl(cust_acct.customer_class_code,
                                             'XX')),
                                        NULL)) AND
               c.segment2 BETWEEN '1101' AND '25582'
          --    24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Profile Option and new condition 
              --                       and app.code_combination_id = c.code_combination_id
               AND acr.cash_receipt_id = ps.cash_receipt_id AND
               acr.set_of_books_id = '2021'
               --24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Prameter 
        --24-APR-2023|EY|ATUL ROLLOUT CHANGES| END 
        --  p_in_bal_segment_low and p_in_bal_segment_high
        -- ps.org_id = p_org_id
   --    AND  NVL(app.DISPLAY,'N') = 'Y'   ---ADDED by NIkita 200324
   --  AND acr.RECEIPT_NUMBER = 'NO.0459FIR2100147'
      --AND Display = 'Y'
         GROUP BY party.party_name,
                  ps.customer_id,
                  cust_acct.account_number,
                  cust_acct.customer_class_code,
                  site.site_use_id,
                  decode(upper('CUSTOMER'),
                         'CUSTOMER',
                         NULL,
                         initcap(NULL)),
                  -999,
                  loc.state,
                  loc.city,
                  acct_site.cust_acct_site_id,
                  cust_acct.cust_account_id,
                  ps.payment_schedule_id,
                  ps.term_id,
                  ps.customer_trx_id,
                  ps.due_date,
                  ps.trx_number,
                  ps.amount_adjusted,
                  ps.amount_applied,
                  ps.amount_credited,
                  ps.gl_date,
                  ps.amount_in_dispute,
                  ps.amount_adjusted_pending,
                  ps.invoice_currency_code,
                  ps.exchange_rate,
                  decode(app.applied_payment_schedule_id,
                         -4,
                         'CLAIM',
                         ps.class),
                  c.segment2,
                  c.segment4,
                  c.segment3,
                  decode(app.status,
                         'UNID',
                         'UNID',
                         'OTHER ACC',
                         'OTHER ACC',
                         'UNAPP'),
                  to_char(NULL),
                  initcap(NULL),
                  ps.org_id
         , ps.CASH_RECEIPT_ID ------------------------------------------------------------- duplicate data 
UNION ALL
        SELECT substrb(nvl(party.party_name,
                           NULL),
                       1,
                       50) cust_name_inv,
               cust_acct.account_number cust_no_inv,
               cust_acct.customer_class_code cust_type,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      NULL,
                      initcap(NULL)),
               initcap(NULL),
               -999,
               site.site_use_id,
               loc.state cust_state_inv,
               loc.city cust_city_inv,
               decode(NULL,
                      NULL,
                      -1,
                      acct_site.cust_acct_site_id) addr_id_inv,
               nvl(cust_acct.cust_account_id,
                   -999) p_cust_id_inv,
               ps.payment_schedule_id,
               initcap(NULL),
               ps.term_id,
               atl_sales_recog_ar_due_date(ps.org_id,
                                           ps.customer_id,
                                           ps.customer_trx_id,
                                           ps.due_date) due_date,
               decode('Y',
                      'Y',
                      crh.acctd_amount,
                      crh.amount),
               ps.trx_number,
               ps.amount_adjusted,
               ps.amount_applied,
               ps.amount_credited,
               crh.gl_date,
               decode(ps.invoice_currency_code,
                      'INR',
                      NULL,
                      decode(crh.exchange_rate,
                             NULL,
                             '*',
                             NULL)),
               nvl(crh.exchange_rate,
                   1),
               c.segment2 company_inv,
               c.segment4 acct,
               c.segment3 cost_center,
               to_char(NULL) cons_billing_number,
               initcap(NULL),
               ps.invoice_currency_code inv_currency,
               ps.org_id org_id,
               ps.customer_id customer_id ,
               crh.CREATED_BY              ----Added By Nikita on 140324 mantis no - FIN-2325 
              ,crh.CREATION_DATE   ----Added By Nikita on 200324 mantis no - FIN-2325 
              ,crh.LAST_UPDATED_BY      ----Added By Nikita on 210324 mantis no - FIN-2325 
              ,crh.LAST_UPDATE_DATE  ----Added By Nikita on 200324 mantis no - FIN-2325  ---------------------------------- who clumn ps.
          FROM hz_cust_accounts            cust_acct,
               hz_parties                  party,
               ar_payment_schedules_all    ps,
               hz_cust_site_uses_all       site,
               hz_cust_acct_sites_all      acct_site,
               hz_party_sites              party_site,
               hz_locations                loc,
               ar_cash_receipts_all        cr,
               ar_cash_receipt_history_all crh,
               gl_code_combinations        c
         WHERE crh.gl_date <= to_date(:p_as_of_date,
                                      'DD-MON-YY') AND
               ps.trx_number IS NOT NULL AND
               upper(rtrim(rpad('I',
                                1))) = 'I' AND upper(NULL) != 'NONE' AND
               ps.customer_id = cust_acct.cust_account_id(+) AND
               cust_acct.party_id = party.party_id(+) AND
               ps.cash_receipt_id = cr.cash_receipt_id AND
               cr.cash_receipt_id = crh.cash_receipt_id AND
               crh.account_code_combination_id = c.code_combination_id AND
               ps.customer_site_use_id = site.site_use_id(+) AND
               site.cust_acct_site_id = acct_site.cust_acct_site_id(+) AND
               acct_site.party_site_id = party_site.party_site_id(+) AND
               loc.location_id(+) = party_site.location_id AND
               decode(upper(NULL),
                      NULL,
                      ps.invoice_currency_code,
                      upper(NULL)) = ps.invoice_currency_code AND
               (crh.current_record_flag = 'Y' OR
               crh.reversal_gl_date >
               to_date(:p_as_of_date,
                        'DD-MON-YY')) AND crh.status NOT IN (decode(crh.factor_flag,
                                                                    'Y',
                                                                    'RISK_ELIMINATED',
                                                                    'N',
                                                                    'CLEARED'),
                'REVERSED') AND NOT EXISTS
         (SELECT 'x'
                  FROM ar_receivable_applications_all ra
                 WHERE ra.cash_receipt_id = cr.cash_receipt_id AND
                       ra.status = 'ACTIVITY' AND
                       applied_payment_schedule_id = -2) AND --  ps.customer_id IN (:P_cust_id) AND
               ps.customer_id = nvl(:p_cust_id,
                                    ps.customer_id) AND
               nvl(cust_acct.customer_class_code,
                   'XX') = upper(decode(NULL,
                                        NULL,
                                        (nvl(cust_acct.customer_class_code,
                                             'XX')),
                                        NULL)) AND
               c.segment2 BETWEEN '1101' AND '25582' AND
               cr.set_of_books_id = '2021'/*24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Prameter */
        -- p_in_bal_segment_low and p_in_bal_segment_high
        --  ps.org_id = p_org_id
        UNION ALL
        SELECT substrb(party.party_name,
                       1,
                       50) cust_name_inv,
               cust_acct.account_number cust_no_inv,
               cust_acct.customer_class_code cust_type,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      NULL,
                      apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                       ps.org_id)) sort_field1_inv,
               apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                ps.org_id) sort_field2_inv,
               decode(upper('CUSTOMER'),
                      'CUSTOMER',
                      -999,
                      ps.cust_trx_type_id) inv_tid_inv,
               site.site_use_id contact_site_id_inv,
               loc.state cust_state_inv,
               loc.city cust_city_inv,
               decode(NULL,
                      NULL,
                      -1,
                      acct_site.cust_acct_site_id) addr_id_inv,
               nvl(cust_acct.cust_account_id,
                   -999) p_cust_id_inv,
               ps.payment_schedule_id payment_sched_id_inv,
               ps.class class_inv,
               ps.term_id,
               atl_sales_recog_ar_due_date(ps.org_id,
                                           ps.customer_id,
                                           ps.customer_trx_id,
                                           ps.due_date) due_date_inv,
               decode('Y',
                      'Y',
                      ps.acctd_amount_due_remaining,
                      ps.amount_due_remaining) amt_due_remaining_inv,
               ps.trx_number invnum,
               ps.amount_adjusted amount_adjusted_inv,
               ps.amount_applied amount_applied_inv,
               ps.amount_credited amount_credited_inv,
               ps.gl_date gl_date_inv,
               decode(ps.invoice_currency_code,
                      'INR',
                      NULL,
                      decode(ps.exchange_rate,
                             NULL,
                             '*',
                             NULL)) data_converted_inv,
               nvl(ps.exchange_rate,
                   1) ps_exchange_rate_inv,
               c.segment2 company_inv,
               c.segment4 acct,
               c.segment3 cost_center,
               to_char(NULL) cons_billing_number,
               apps.arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,
                                                                ps.org_id) invoice_type_inv,
               ps.invoice_currency_code inv_currency,
               ps.org_id org_id,
               ps.customer_id customer_id,
            th.CREATED_BY             ----Added By Nikita on 140324  mantis no - FIN-2325 
             ,th.CREATION_DATE  ----Added By Nikita on 200324 mantis no - FIN-2325 
             ,th.LAST_UPDATED_BY     ----Added By Nikita on 140324 mantis no - FIN-2325 
            ,th.LAST_UPDATE_DATE  ----Added By Nikita on 200324  mantis no - FIN-2325  ----------------------------- add who column ps.
          FROM hz_cust_accounts           cust_acct,
               hz_parties                 party,
               ar_payment_schedules_all   ps,
               hz_cust_site_uses_all      site,
               hz_cust_acct_sites_all     acct_site,
               hz_party_sites             party_site,
               hz_locations               loc,
               ar_transaction_history_all th,
               ar_xla_ard_lines_v         dist,
               gl_code_combinations       c,
               hr_operating_units         hou /*24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Profile Option */
         WHERE ps.gl_date <= to_date(:p_as_of_date,
                                     'DD-MON-YY') AND
               upper(rtrim(rpad('I',
                                1))) = 'I' AND
               ps.customer_site_use_id = site.site_use_id AND
               site.cust_acct_site_id = acct_site.cust_acct_site_id AND
               acct_site.party_site_id = party_site.party_site_id AND
               loc.location_id = party_site.location_id AND
               ps.gl_date_closed > to_date(:p_as_of_date,
                                           'DD-MON-YY') AND ps.class = 'BR' AND
               decode(upper(NULL),
                      NULL,
                      ps.invoice_currency_code,
                      upper(NULL)) = ps.invoice_currency_code AND
               th.transaction_history_id =
               (SELECT MAX(transaction_history_id)
                  FROM ar_transaction_history th2, ar_xla_ard_lines_v dist2
                 WHERE th2.transaction_history_id = dist2.source_id AND
                       dist2.source_table = 'TH' AND
                       th2.gl_date <= to_date(:p_as_of_date,
                                              'DD-MON-YY') AND
                       dist2.amount_dr IS NOT NULL AND
                       th2.customer_trx_id = ps.customer_trx_id) AND
               th.transaction_history_id = dist.source_id AND
               dist.source_table = 'TH' AND dist.amount_dr IS NOT NULL AND
               dist.source_table_secondary IS NULL AND
               dist.code_combination_id = c.code_combination_id AND
               cust_acct.party_id = party.party_id AND -- ps.customer_id IN (:P_cust_id) AND
               ps.customer_id = nvl(:p_cust_id,
                                    ps.customer_id) AND
               nvl(cust_acct.customer_class_code,
                   'XX') = upper(decode(NULL,
                                        NULL,
                                        (nvl(cust_acct.customer_class_code,
                                             'XX')),
                                        NULL)) AND
               ps.customer_id = cust_acct.cust_account_id AND
               ps.customer_trx_id = th.customer_trx_id AND
               ps.org_id = hou.organization_id /*24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Parameter */
               AND hou.set_of_books_id = '2021' /*24-APR-2023|EY|ATUL ROLLOUT CHANGES| Addition of Ledger Prameter */
               AND c.segment2 BETWEEN '1101' AND '25582' --     p_in_bal_segment_low and p_in_bal_segment_high
        --ps.org_id = p_org_id
       ) abc
 WHERE amt_due_remaining_inv / ps_exchange_rate_inv != 0
-- and abc.due_date_inv <to_date(as_of_date,'DD-MON-YYYY')--and amt_due_remaining_inv > 0
 GROUP BY abc.cust_name_inv,
          customer_id,
          abc.invoice_type_inv,
          abc.cust_no_inv,
          abc.cust_type,
          abc.due_date_inv,
          abc.invnum,
          abc.inv_currency,
          abc.ps_exchange_rate_inv,
          abc.class_inv, -- 57198
          abc.gl_date_inv,
          abc.term_id,
          abc.org_id,
          abc.payment_sched_id_inv,
          abc.company_inv,
          abc.acct,
          abc.cost_center ,
    /*         ps.CREATED_BY             ----Added By Nikita on 140324
         ,ps.CREATION_DATE     ----Added By Nikita on 140324
        ,ps.LAST_UPDATED_BY   ----Added By Nikita on 140324
         ,ps.LAST_UPDATE_DATE  ----Added By Nikita on 140324 */
          abc.CREATED_BY             ----Added By Nikita on 140324 mantis no - FIN-2325 
         ,abc.CREATION_DATE     ----Added By Nikita on 140324 mantis no - FIN-2325 
        ,abc.LAST_UPDATED_BY   ----Added By Nikita on 140324 mantis no - FIN-2325 
         ,abc.LAST_UPDATE_DATE  ----Added By Nikita on 140324 mantis no - FIN-2325  ---------------------------- abc.
 ORDER BY SUM(nvl(abc.amt_due_remaining_inv,
                  0)) DESC;
                  
                  
       