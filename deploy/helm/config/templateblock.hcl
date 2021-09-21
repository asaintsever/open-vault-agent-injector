template {
    destination = "/opt/ovai/secrets/<OVAI_SECRETS_DESTINATION>"
    contents = <<EOH
    <OVAI_SECRETS_TEMPLATE_CONTENT>
    EOH
    command = "<OVAI_SECRETS_TEMPLATE_COMMAND_TO_RUN>"
    wait {
        min = "1s"
        max = "2s"
    }
}