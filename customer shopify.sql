CREATE TABLE LFINTEGRATION.XXLF_SHOPIFY_EBS_ACCNTS_IMP_STG (
  -- 1) Identity / Integration controls
  G_ID                  VARCHAR2(100),
  LFINTG_EXECUTION_ID       NUMBER,
  ORACLE_STATUS             VARCHAR2(24)   DEFAULT 'NEW',---p/r/e
  ORACLE_MESSAGE            VARCHAR2(3500), --ebs message
  OIC_STATUS                VARCHAR2(24), --"NEW"
  OIC_MESSAGE               VARCHAR2(3500),
 
  -- 2) OIC input  
  OIC_COMPANY_NAME          VARCHAR2(360),
  OIC_NAME                  VARCHAR2(360),
  OIC_CUSTOMER_LOCATION_NAME VARCHAR2(360),
 
  -- Bill-To  
  OIC_BILLING_STREET        VARCHAR2(240),
  OIC_BILLING_CITY          VARCHAR2(60),
  OIC_BILLING_POSTALCODE    VARCHAR2(60),
  OIC_BILLING_STATE         VARCHAR2(60),
  OIC_BILLING_COUNTY        VARCHAR2(60),           -- OIC may not send
  OIC_BILLING_COUNTRY       VARCHAR2(60),
 
  -- Ship-To  
  OIC_SHIPPING_STREET       VARCHAR2(240),
  OIC_SHIPPING_CITY         VARCHAR2(60),
  OIC_SHIPPING_POSTALCODE   VARCHAR2(60),
  OIC_SHIPPING_STATE        VARCHAR2(60),
  OIC_SHIPPING_COUNTY       VARCHAR2(60),           -- OIC may not send
  OIC_SHIPPING_COUNTRY      VARCHAR2(60),
 
  -- Contact  
  OIC_FIRST_NAME            VARCHAR2(100),
  OIC_LAST_NAME             VARCHAR2(100),
  OIC_PHONE                 VARCHAR2(40),
  OIC_EMAIL                 VARCHAR2(200),
 
  -- Scifit inputs from OIC
  OIC_SALES_CHANNEL_LOOKUP  VARCHAR2(200),
  OIC_SCIFIT_DEALER_FLAG    VARCHAR2(10),
  OIC_DEALER_END_CUSTOMER   VARCHAR2(200),
  OIC_BILLTO_LOCATION_ID    VARCHAR2(200),
 ------------------------------------------------------
  -- 3) Party / Company in EBS  
  COMPANY_NAME              VARCHAR2(360),          -- normalized from OIC_COMPANY_NAME
  PARTY_NAME                VARCHAR2(360),          -- final party; SCIFIT may use location name
  CUSTOMER_LOCATION_NAME    VARCHAR2(360),          -- normalized from OIC_CUSTOMER_LOCATION_NAME
 
  -- 4) EBS Bill-To 
  BILL_TO_ADDRESS1          VARCHAR2(240),
  BILL_TO_ADDRESS2          VARCHAR2(240),
  BILL_TO_ADDRESS3          VARCHAR2(240),
  BILL_TO_ADDRESS4          VARCHAR2(240),
  BILL_TO_CITY              VARCHAR2(60),
  BILL_TO_POSTAL_CODE       VARCHAR2(60),
  BILL_TO_STATE             VARCHAR2(60),
  BILL_TO_PROVINCE          VARCHAR2(60),
  BILL_TO_COUNTY            VARCHAR2(60),
  BILL_TO_COUNTRY           VARCHAR2(60),
 
  -- 5) EBS Ship-To 
  SHIP_TO_ADDRESS1          VARCHAR2(240),
  SHIP_TO_ADDRESS2          VARCHAR2(240),
  SHIP_TO_ADDRESS3          VARCHAR2(240),
  SHIP_TO_ADDRESS4          VARCHAR2(240),
  SHIP_TO_CITY              VARCHAR2(60),
  SHIP_TO_POSTAL_CODE       VARCHAR2(60),
  SHIP_TO_STATE             VARCHAR2(60),
  SHIP_TO_PROVINCE          VARCHAR2(60),
  SHIP_TO_COUNTY            VARCHAR2(60),
  SHIP_TO_COUNTRY           VARCHAR2(60),
 
  -- 6) Normalized address fields
  NORM_BILLTO_COUNTRY_CODE VARCHAR2(2),
  NORM_BILLTO_STATE_CODE   VARCHAR2(10),
  NORM_BILLTO_CITY         VARCHAR2(240),
  NORM_BILLTO_POSTAL       VARCHAR2(20),
  NORM_BILLTO_COUNTY       VARCHAR2(240),
  NORM_SHIPTO_COUNTRY_CODE VARCHAR2(2),
  NORM_SHIPTO_STATE_CODE   VARCHAR2(10),
  NORM_SHIPTO_CITY         VARCHAR2(240),
  NORM_SHIPTO_POSTAL       VARCHAR2(20),
  NORM_SHIPTO_COUNTY       VARCHAR2(240),
 
  -- 7) EBS Contact
  CONTACT_FIRST_NAME        VARCHAR2(100),
  CONTACT_LAST_NAME         VARCHAR2(100),
  CONTACT_PHONE             VARCHAR2(40),
  CONTACT_EMAIL             VARCHAR2(200),
 
  -- 8) Flags & usage (final)
  PRIMARY_BILLING_FLAG      VARCHAR2(1),
  PRIMARY_SHIPPING_FLAG     VARCHAR2(1),
  ADDRESS_USAGE             VARCHAR2(240),
 
  -- 9) Sales / OM (resolved)
  SALES_CHANNEL_LOOKUP      VARCHAR2(200),    
  PROFILE_CLASS_NAME        VARCHAR2(240),
  PRICE_LIST_CODE           VARCHAR2(60),
  PAYMENT_TERM              VARCHAR2(240),
  FOB_POINT                 VARCHAR2(60),
  FREIGHT_TERMS             VARCHAR2(60),
  PAYMENT_TERM_ID           NUMBER,
  PROFILE_CLASS_ID          NUMBER,
  PRICE_LIST_ID             NUMBER,
 
  -- 10) SCIFIT / Dealer (final)
  SCIFIT_DEALER_FLAG        VARCHAR2(1),
  DEALER_END_CUSTOMER       VARCHAR2(1),
  BILLTO_LOCATION_ID        VARCHAR2(200),
 
  -- 11) Tax & logging
  TAX_EXEMPT_NUMBER         VARCHAR2(60),
  LOG_NOTES                 CLOB,
 
  -- 12) Oracle output IDs (separate) + optional concatenated display
  ACCOUNT_NUMBER            VARCHAR2(100),
  CUST_ACCOUNT_ID           NUMBER,
  PARTY_ID                  NUMBER,
  PARTY_SITE_NUMBER         VARCHAR2(100),
  LOCATION_ID               NUMBER,
  CONCAT_ID_COLUMNS         VARCHAR2(240),
 
  -- 13) Audit
  CREATION_DATE             DATE,
  CREATED_BY                NUMBER,
  LAST_UPDATE_DATE          DATE,
  LAST_UPDATED_BY           NUMBER
);