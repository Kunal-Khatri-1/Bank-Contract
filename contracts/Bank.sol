// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // making the owner of the bank immutable
    address payable immutable private owner;
    // storing the contract address in bankcontractAdd variable
    // making it immutable
    // making it payable to accept ethers from other accounts
    address payable private immutable bankContractAdd = payable( address( this ) );

    // gives status of account corresponding to an address. If the account with the address is opened then accOpned.OPENED is put as value and vice versa
    // accOpened.NOT_OPENED is the default value
    enum accOpned { NOT_OPENED, OPENED }

    // this structure is mapped to account addresss in mapping named ledger
    // this is the format in which the details are stored
    struct accInfo {
        string name;
        uint amount;
        accOpned status;
        uint16 password;
    }

    // creating mapping of account addresses with accInfo structure
    // this is the record that stores information for each address(account number)
    // address is the key and is considered as the account number in this contract
    mapping( address => accInfo ) private ledger;

    // Events for different functions
    // emitted when ethers are successfully transfered from one account to another
    event transferedEvent( address _from, address _to, uint _value );
    // emitted when ethers are successfully opened a bank account
    event accOpnedEvent( address _from, string _name, uint _balance, accOpned);
    // emitted when ethers are successfully closed a bank account
    event accClosedEvent( address _from );
    // emitted when ethers are successfully deposited the mentioned amount of ethers
    event depositEvent( address _from, uint _value );

    // contructor is used to set the owner of the contract
    constructor() {
        // address which deploy contract will set as the owner
        owner =  payable( msg.sender );
    }


    // receive is so that this smart contract can accept Ehters
    receive() external payable {}



    // this function gives the total ethers the bank contract has
    function viewContBal() public view returns( uint balance ) {
        return bankContractAdd.balance;
    }

    // function to open account in bank
    // _custPassword is arguement taken by the user/customer. This will be required to authenticate the user later when the user/customer transfers/deposits ethers
    // user/customer will call this function with the amount of ethers the user/customer deposit in the account
    function openAcc( string memory _name, uint16  _custPassword ) public payable returns( bool _success ){
        // checking if the account is not already opened with this address.
        require( ledger[ msg.sender ].status == accOpned.NOT_OPENED, "Account already opened with this address" );

        // transferring the ether customer/user sent when the function was called
        bankContractAdd.transfer( msg.value );

        // if account is not opened with the given address then open the account
        // setting the _custPassword as the password for the address in the ledger mapping
        // setting the amount the user has in the bank account as the amount the user sent to the contract when this function was called
        ledger[ msg.sender ] = accInfo( _name, msg.value, accOpned.OPENED, _custPassword );

        // emit the event that account is opened
        emit accOpnedEvent( msg.sender, _name, msg.value, accOpned.OPENED );

        // return true if account is added
        return true;
    }


    // function to close account in bank
    // user/customer calls this function when the user/customer wants to close the bank account
    function closeAcc( uint16 _custPassword ) public payable returns( bool _success ){
        // checking if the account exists corresponding to given address
        require( ledger[ msg.sender ].status == accOpned.OPENED, "This address does not have a bank account" );
        // checking if the given password(_custPassword) matches the password value in ledger for the account for validation
        require( _custPassword == ledger[ msg.sender ].password, "Wrong password. Try again." );

        // transfer the ether back from bankContractAdd to msg.sender(user/customer)
        payable(msg.sender).transfer( ledger[ msg.sender ].amount );
        // if account exists corresponding to given address exists then set the name as empty string "", balance to 0 and change status to account not opened by accOpend.NOT_OPENED and password to 0
        ledger[ msg.sender ] = accInfo("" , 0, accOpned.NOT_OPENED, 0 );

        // emit event that account is closed
        emit accClosedEvent( msg.sender );

        // return if account is removed
        return true;
    }

    // function accepts Ethers from sender ( msg.sender ) and sends it to the receiver address ( _toAccNo )
    // user/customer calls this function when the user/customer(sender) wants to send some ethers from their account to other user's/customer's(receiver) account
    // _value is the arguement sender gives which tells how many ethers the sender wants to send to the receiver
    // this function does not transfers ethers to ethereum address. This function just changes the ownership ethers in the contract
    // sender will loose ownership of _value amount of coins in the contract
    // receiver will gain ownership of _value amount of ethers in the contract
    function transaction( address payable _toAccNo, uint16 _custPassword, uint _value ) public payable returns( bool _success ) {
        // Mandating that the sender has a bank account for the transaction.
        require( ledger[ msg.sender ].status == accOpned.OPENED, "You don't have the bank account. Please open the bank account for this operation." );
        // Mandating that the receiver has a bank account for accepting the Ethers.
        require( ledger[ _toAccNo ].status == accOpned.OPENED, "Receiver don't have the bank account. Transaction failed." );
        // Mandating that the sender cannot send 0 ethers to the receiver
        require( _value > 0, "Cannot give 0 ethers to receiver. Please give other positive value." );
        // Mandating that the sender mentions the amount of ethers he/she want to send only through _value arguement/field of this function 
        require( msg.value == 0, "Please give the amount from the _value field." );
        // checking if the given password(_custPassword) matches the password value in ledger for the account for validation
        require( _custPassword == ledger[ msg.sender ].password, "Wrong password. Try again." );
        // the account must have enough balance to send it to other person
        require( ledger[ msg.sender ].amount >= _value, "Not enough balance to transfer this amount." );
        
        // Updating the ledger state of the bank
        // decreasing the sender's account amount/balance by the value
        // sender is loosing the ownership of _value amount of ethers in the bank cotract
        ledger[ msg.sender ].amount -= _value;
        // increasing the receiver's account amount/balance 
        // receiver is gaining ownership of _value amount of ethers in the bank contract
        ledger[ _toAccNo ].amount += _value;

        // emitting the transfer event
        emit transferedEvent( msg.sender, _toAccNo, msg.value );
        // returning true if transaction is successful
        return true;
    }


    // function to view account details
    // user/customer calls this method to see his account details
    function viewAccDetails( uint16 _custPassword ) public view returns (
        string memory _custAddress, 
        uint _amount, 
        accOpned _status 
        ) {
                // checking if the given password(_custPassword) matches the password value in ledger for the account for validation
                require( _custPassword == ledger[ msg.sender ].password, "Wrong password. Try again.");
                return(
                    ledger[ msg.sender ].name,
                    ledger[ msg.sender ].amount,
                    ledger[ msg.sender ].status
                );
            }


    // this function deposit ethers to account
    // user/customer calls this method to deposit the mention amount of ethers in his/her account in the bank
    function deposit( uint16 _custPassword ) public payable returns( bool _success ) {
        // Mandating that the sender has a bank account for the transaction.
        require( ledger[ msg.sender ].status == accOpned.OPENED, "You don't have the bank account. Please open the bank account for this operation." );
        // checking if the given password(_custPassword) matches the password value in ledger for the account for validation
        require( _custPassword == ledger[ msg.sender ].password, "Wrong password. Try again." );
        // Mandating that amount deposited is greater than 0
        require( msg.value > 0, "Cannot deposit 0 ethers to your account. Please give other positive value." );

        // updating ether amount in sender's account
        ledger[ msg.sender ].amount += msg.value;

        // emitting event for deposit
        emit depositEvent( msg.sender, msg.value );

        // returning true if deposit is successful
        return true;
    }
}