
# Compliant Private Tokens Workshop - Token Template

This is the Leo project scaffolding for the Aleo compliant private tokens workshop.  For more information, head over to the [main repository](https://github.com/alex-aleo/private-token-workshop).

[Repo Location](https://github.com/adamsimonini/aleo-private-token-workshop)

## Private/public vs Onchain/offchain

## Transitions
So transitions change state. They can do this on chain publicly be calling an async function to commit a mutation...

Or they can change state by generating a record along with a zk proof certificate, and send that to the blockchain. When done via a record, the execution is done on the client, and so on async onchain function is optional

## Versioning
Data on the blockchain is immutable, including program code. Updating a program means uploading a new version to supersede the previous one.