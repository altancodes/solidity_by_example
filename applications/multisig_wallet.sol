/* The wallet owners can:
1. submit a transaction
2. approve and revoke approval of pending transactions
3. anyone can execute a transaction after enough owners has approved it
*/


/*
The first is “storage”, where all the contract state variables reside. 
Every contract has its own storage and it is persistent between function calls and quite expensive to use.

The second is “memory”, 
this is used to hold temporary values. 
It is erased between (external) function calls and is cheaper to use.

The third one is the stack, 
which is used to hold small local variables. 
It is almost free to use, but can only hold a limited amount of values.

*/

pragma solidity ^0.8.10;

contract MultiSigWallet {

    // Events
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    event ConfirmTransaction(
        address indexed owner,
        uint indexed txIndex
    );

    event ExecuteTransaction(
        address indexed owner,
        uint indexed txIndex
    )

    event RevokeTransaction(
        address indexed owner,
        uint indexed txIndex
    )

    address[] public owners;
    mapping(address=>bool) isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to,
        uint value,
        bytes data,
        bool executed,
        uint numConfirmations
    }

    mapping(uint => mapping(
        address => bool
    )) public isConfirmed;

    Transaction[] public transactions;

    // Modifiers
    // Allows functions to be executed only by the owner
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not an owner of the multi sig wallet");
    }

    // Makes sure that the transactions exists
    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "tx does not exist");
    }

    // Makes sure that the transaction is not executed
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx not executed");
    }

    // Makes sure that the transaction is not confirmed
    modifier notConfirmed(uint _txIndex) {
        require(transactions[_txIndex].numConfirmations < transactions[_txIndex].numConfirmationsRequired);
    }

    /* Memory keyword - allows you to have space for the addresses to come in runtime */
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "there needs to be at least one owner");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= owners.length);

        for (int i = 0; i < _owners.length; i++) {
            address owner = _owners[i]; 

            require(owner != address(0), "address is not valid");
            require(!isOwner[owner], "address is already used");
            
            // Perform checks on the owner
            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        // Received msg.value ether from msg.sender to this address
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to, 
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        Transaction newTransaction = Transaction({
            _to, 
            _value, 
            _data, 
            false,
            0
        });

        transactions.push(newTransaction);

        emit SubmitTransaction(
            msg.sender,
            txIndex, 
            _to, 
            _value, 
            _data
        );
    }

    function confirmTransaction(uint _txIndex) public 
    onlyOwner 
    txExists(_txIndex) 
    notExecuted(_txIndex) 
    notConfirmed (_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true; 

        // Confirms the transaction
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public 
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations > numConfirmationsRequired,
            "Number of comfirmations required is not met"
        );

        bool (success, _) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        transaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(_txIndex) public
    onlyOwner 
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        
        emit RevokeConfirmation(msg.sender, _txIndex);
    }
     
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}