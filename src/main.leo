// OFAC is a US Treasury Depoarment agency maining sanctions lists. This is important for regulatory compliance.
import workshop_ofac.aleo;

/*
====================================================================================================================
TASK 0: Name Your Token

TODO: 
    1. Choose what your token program will be named! This should be longer than 10 characters to avoid additional
       network fees and not conflict with any existing program on the network
        - ex) `dogecoin_token.aleo`
    2. Change the name of the program below
        - ex) `program √.aleo {`
    3. Change the "program" field in the program.json file to match the name of your new program

====================================================================================================================  
*/
program the_best_token.aleo {
    /* 
        A mapping is declared as mapping {name}:. Mappings contain key-value pairs and must be defined within a program.
        Mappings are stored publicly on-chain, but are program-scopped state. 
        It merely lists address that have entries written for that program.

        Balances is a public key-value store owned by my program, like its own, scoped dictionary of relevant addresses.
    */

    mapping balances: address => u64;  // On-chain mapping between user addresses and public token balances

    record Token {
        owner: address,  // The token owner
        amount: u64,     // The token amount
    }

    @noupgrade
    async constructor() {}





    /*
    ====================================================================================================================
    TASK 1: Mint (Public)

    This feature mints new tokens by updating the public mapping value of the recipient
    
    TODO:
        `mint_public`:
            1. Query the `address_check` function in `workshop_ofac.aleo` with the `recipient` field
            2. Pass the returned Future and other appropriate fields to the `mint_public_onchain` function

        `mint_public_onchain`:
            1. Await the `address_check` Future
            2. Set the value for `recipient` in the `balances` mapping to the current value plus `amount` 

    
    ====================================================================================================================  
    */

    /*
        FUTURES
        A future is equivalent to the call graph of the on-chain execution and is explicitly used when finalizing an execution. 
        Instead of constructing the call graph implicitly from the code, the transition/circuit explicitly outputs a future, 
        specifying which code blocks to run on-chain and how to run them.
    */

    // * transitions are offchain functions that are executed offchain and have their corresponding zero-knowledge proof verified onchain.
    async transition mint_public(
        public recipient: address,  
        public amount_to_mint: u64
    ) -> Future {
        // we imported workshow_ofac.aleo above, and now we're using one of its methods. think of it like an imported package
        let address_check : Future = workshop_ofac.aleo/address_check(recipient);

        return mint_public_onchain(recipient, amount_to_mint, address_check);
    }

    // * async functions are onchain functions that are executed onchain.
    async function mint_public_onchain(
        public recipient: address, 
        public amount_to_mint: u64,
        public address_check : Future
    ) -> Future{
        let mint_return : Future = async {
            address_check.await();
            // ? Do we not need a conditional check here? If not, what is returned on failure?
            // await address verification before continuing

            // * balances use u64, so they cannot take negative numbers 
            let current_balance : u64 = balances.get_or_use(recipient, 0u64); //0u64 is the default value of zero if the recipient is not found
            balances.set(recipient, current_balance + amount_to_mint);
        };
        return mint_return;
    }





    /*
    ====================================================================================================================
    TASK 2: Mint (Private)

    This feature mints new tokens by initializing a new record with the specified amount of tokens for the recipient.
    
    TODOs: 
        `mint_private`:
            1. Query the `address_check` function in `workshop_ofac.aleo` with the `recipient` field
            2. Initialize a Token record with the `recipient` as the owner and the `amount` as the amount
            3. Return the Token record and pass the Future to the `mint_private_onchain_sanction_check` function

        `mint_private_onchain_sanction_check`:  
            1. Await the `address_check` Future
    
    ====================================================================================================================  
    */
    /* 
        Since address are public, and balances stores addresses on-chain, we must find a different way to store the recipient's address privately.
        We do this by initializing a Token record with the recipient as the owner and the amount as the amount.
        Then we pass the Future to the `mint_private_onchain` function.

        A Token record is a private, on-chain record. Its contents are private, but the record itself is public. Only the owner can decrypt it.
    
        * The transaction is private: the sender, the receiver, the functionl called, the values, and the success/failure.
        * The recipients gains access to the Token record by decrypting it with their private key. The token record is hosted on-chain, but the contents are encrypted.

        * What the blockchain can see:
            - program and function execution are public
        
        * What the blockchain CANNOT see:
            - caller (encrypted)
            - function inputs (encrypted)
            - function outputs (encrypted)
            - recipient (encrypted)
            - values (encrypted)
    */
    async transition mint_private(
        private recipient: address, 
        private amount: u64
    ) -> (Token, Future) {
        let address_check: Future = workshop_ofac.aleo/address_check(recipient);
        let token: Token = Token {
            owner: recipient,
            amount: amount
        };
        return (token, mint_private_onchain_sanction_check(address_check));
    }

    async function mint_private_onchain_sanction_check(
        address_check: Future
    ) -> Future {
        let sanction_check_return: Future = async {
            address_check.await();
            // No additional logic needed for private mint
            // The Token record is already created and returned above
        };
        return sanction_check_return;
    }

    /*
    ====================================================================================================================
    TASK 3: Transfer (Public)

    This feature publicly transfers tokens between two users by deducting the transfer amount from the sender's balance
    in the public mapping and adding the same value to the recipient's balance
    
    TODO:
        `transfer_public`:
            1. Query the `address_check` function in `workshop_ofac.aleo` with the `recipient` field
            2. Pass the returned Future and other appropriate fields to the `transfer_public_onchain` function
                - For the `sender` field, you can use `self.signer` to specify the address that initialized the function call

        `transfer_public_onchain`:
            1. Await the `address_check` Future
            2. Set the value for `sender` in the `balances` mapping to the sender's current value minus `amount` 
            3. Set the value for `recipient` in the `balances` mapping to the recipient's current value plus `amount` 
    
    ====================================================================================================================  
    */

    async transition transfer_public(
        public recipient: address, 
        public amount: u64
    ) -> Future {
        let address_check : Future = workshop_ofac.aleo/address_check(recipient);
        let sender: address = self.signer; // ? https://developer.aleo.org/guides/aleo/language/#special-operands

        return transfer_public_onchain(sender, recipient, amount, address_check);
    }
    async function transfer_public_onchain(
        public sender: address, 
        public recipient: address, 
        public amount: u64,
        public address_check : Future
    ) -> Future {
        let transfer_return : Future = async {
            // await address verification before continuing
            address_check.await();

            // subtract from sender 
            let sender_balance: u64 = balances.get_or_use(sender, 0u64);
            assert(sender_balance >= amount); 
            balances.set(sender, sender_balance - amount);

            // add to recipient
            let recipient_balance: u64 = balances.get_or_use(recipient, 0u64);
            balances.set(recipient, recipient_balance + amount);

        };
        return transfer_return;
    }





    /*
    ====================================================================================================================
    TASK 4: Transfer (Private)

    This feature privately transfers tokens between two users by consuming the sender's Token record and producing two 
    new Token records.  The first is a Token record for the recipient with the amount sent, and the second is a new Token 
    record for the sender with the leftover amount.
    
    TODO:
        `transfer_private:
            1. Query the `address_check` function in `workshop_ofac.aleo` with the `recipient` field
            2. Initialize a Token record with the `recipient` as the owner and the `amount` as the amount
            3. Initialize a Token record with the `sender` as the owner and the remaining balance as the amount
            4. Return both Token records and pass the Future to the `mint_private_onchain` function

        `transfer_private_onchain`:
            1. Await the `address_check` Future
    
    
    ====================================================================================================================  
    */
    async transition transfer_private(
        private sender: Token, // this transition only works with private tokens
        private recipient: address, 
        private amount: u64
    ) -> (Token, Token, Future) {
        let address_check : Future = workshop_ofac.aleo/address_check(recipient);

        assert(sender.amount >= amount);

        let sender_token : Token = Token {
            owner: sender.owner,
            amount: sender.amount - amount
        };
        let recipient_token : Token = Token {
            owner: recipient,
            amount: amount
        };
        return (sender_token, recipient_token, transfer_private_onchain(address_check));
    }

    async function onchain_sanction_check(
        public address_check : Future
    ) -> Future {
        let transfer_return : Future = async {
            address_check.await();
            // No additional logic needed for private transfer
            // The Token records are already created and returned above
        };
        return transfer_return;
    }





    /*
    ====================================================================================================================
    BONUS TASKS:

    For those looking for an extra challenge, implement the following additional functions:
        - transfer_private_to_public()
        - transfer_public_to_private()

    Additionally, in practice you'll likely want to have some advanced functionality, such as allowing authorized users and programs
    to manage your funds:
        - approve_public [will require an additional `allowances` mapping]
        - approve_private
        - transfer_from() [Aleo only supports public transfer_from due to how records are implemented]
        - burn_public()
        - burn_private()


    Don't forget to include OFAC compliance checks!
    
    ====================================================================================================================  
    */
}
