{
  companies(
    first: 50
    query: "name:'Cett Test'"
    # query: "created_at:<'2025-08-19T19:00:00Z'"
    sortKey: CREATED_AT
    reverse: true
  ) {
    edges {
      node {
        id
        name
        createdAt
        externalId
        contacts(first: 50){
            edges {
      node {
            id
           customer{
               displayName
               email
               firstName
               lastName
               id
               phone

           }
      }}
        }
        metafields(first: 10) {
          edges {
            node {
              id
              namespace
              key
              value
              type
              owner {
                __typename
                 ... on Company {
                  id
                }
               
              }
            }
          }
        }
        locations(
          first: 50
          query:"name:'Main location'"
        #   query: "created_at:>'2025-08-12T19:00:00Z'"
          sortKey: CREATED_AT
          reverse: true
        ) {
          edges {
            node {
              id
              name
              createdAt
              billingAddress {
                address1
                address2
                city
                companyName
                country    
                countryCode
                province
              }
              shippingAddress {
                    address1
                    address2
                    city
                    companyName
                    country
                    countryCode
                    province
                }
            }
          }
        }
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
