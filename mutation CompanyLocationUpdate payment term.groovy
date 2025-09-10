mutation CompanyLocationUpdate {
    companyLocationUpdate(
        companyLocationId: "gid://shopify/CompanyLocation/5686952223"
        input: { buyerExperienceConfiguration: {
             paymentTermsTemplateId: "gid://shopify/PaymentTermsTemplate/2" } }
    ) {
        companyLocation {
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
        }
    }
}
