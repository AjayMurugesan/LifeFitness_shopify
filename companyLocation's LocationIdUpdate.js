mutation {
  companyLocationUpdate(
    companyLocationId:  "gid://shopify/CompanyLocation/5686952223",
    input: {
      externalId: "1234-c"
    }
  ) {
    companyLocation {
      id
      externalId
    }
    userErrors {
      field
      message
    }
  }
}
