{
    companyLocations(first: 50, query: "created_at:>'2025-06-11T19:00:00Z'") {
        edges {
            node {
                buyerExperienceConfiguration {
                    paymentTermsTemplate {
                        description
                        dueInDays
                        id
                        name
                        paymentTermsType
                        translatedName
                    }
                }
                id
                name
                createdAt
                externalId
                metafields(first: 20) {
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
                roleAssignments(first: 10) {
                    edges {
                        node {
                            id
                            role {
                                name
                            }
                            companyContact {
                                id
                                customer {
                                    id
                                    displayName
                                    email
                                    firstName
                                    lastName
                                    phone
                                    email
                                }
                            }
                        }
                    }
                }
                company {
                    id
                    name
                    createdAt
                    locationsCount {
                        count
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
                billingAddress {
                    address1
                    address2
                    city
                    companyName
                    country
                    countryCode
                    province
                }
                taxExemptions
                taxSettings {
                    taxExempt
                    taxExemptions
                    taxRegistrationId
                }
            }
        }
        pageInfo {
            hasNextPage
            endCursor
        }
    }
}




