mutation {
  metafieldsSet(
    metafields: [
      {
      namespace: "custom"
        key: "company_tax_exempt"
        value: "No"
        type: "single_line_text_field"
        ownerId: "gid://shopify/CompanyLocation/5686952223"
      }
    ]
  ) {
    metafields {
      id
      key
      namespace
      value
      createdAt
      updatedAt
    }
    userErrors {
      field
      message
      code
    }
  }
}
