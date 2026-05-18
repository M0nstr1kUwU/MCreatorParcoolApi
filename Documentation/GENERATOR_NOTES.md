# generator.yaml additions

Add this entry if it does not exist yet:

```yaml
  - template: party_api_name_visibility.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiNameVisibility.java"
```

The following templates are full replacements and should already exist in generator.yaml:

```yaml
  - template: party_api_system.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/party/PartyApiSystem.java"

  - template: party_api_network.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/network/PartyApiNetwork.java"

  - template: party_api_client.java.ftl
    name: "@SRCROOT/@BASEPACKAGEPATH/client/PartyApiClient.java"
```
