pragma solidity ^0.6.0;


import '../accesscontrol/FarmerRole.sol';
import '../accesscontrol/DistributorRole.sol';
import '../accesscontrol/RetailerRole.sol';
import '../accesscontrol/ConsumerRole.sol';
import '../ownership/Ownable.sol';



contract SupplyChain is Ownable, FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Universal Product Code (UPC)
  uint  upc;

  // Stock Keeping Unit (SKU)
  uint  sku;

  // UPC => item.
  mapping (uint => Item) items;


  // track item path
  mapping (uint => string[]) itemsHistory;


  enum State
  {
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
    }

  State constant defaultState = State.Harvested;

  // Item Structure
  struct Item {
    uint    sku;
    uint    upc;
    address payable ownerID;  // Address of the current owner
    address payable originFarmerID; // Address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID <- upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint upc);
  event Processed(uint upc);
  event Packed(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);


  // verify caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address, "This account is not the owner of this item");
    _;
  }

  // check the price is sufficient or not
  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "The amount sent is not sufficient for the price");
    _;
  }

  // check price and refund balance(Distributor)
  modifier checkValueForDistributor(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].distributorID.transfer(amountToReturn);
  }


    // check price and refund balance(Distributor)
  modifier checkValueForConsumer(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].consumerID.transfer(amountToReturn);
  }

  // check the corresponding state with event
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested, "The Item is not in Harvested state!");
    _;
  }


  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed, "The Item is not in Processed state!");
    _;
  }


  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed, "The Item is not in Packed state!");
    _;
  }


  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale, "The Item is not in ForSale state!");
    _;
  }


  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold, "The Item is not in Sold state!");
    _;
  }


  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped, "The Item is not in Shipped state!");
    _;
  }


  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received, "The Item is not in Received state!");
    _;
  }


  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased, "The Item is not in Purchased state!");
    _;
  }

  //set sku and upc to 1
  constructor() public payable {
    sku = 1;
    upc = 1;
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(
  uint _upc,
  address payable _originFarmerID,
  string memory _originFarmName,
  string memory _originFarmInformation,
  string memory _originFarmLatitude,
  string memory _originFarmLongitude,
  string memory productNotes) public

  onlyFarmer
  {

    Item memory newItem;
    newItem.upc = _upc;
    newItem.ownerID = _originFarmerID;
    newItem.originFarmerID = _originFarmerID;
    newItem.originFarmName = _originFarmName;
    newItem.originFarmInformation = _originFarmInformation;
    newItem.originFarmLatitude = _originFarmLatitude;
    newItem.originFarmLongitude = _originFarmLongitude;
    newItem.productNotes = productNotes;
    newItem.sku = sku;
    newItem.productID = _upc + sku;

    sku = sku + 1; // Increment sku

    newItem.itemState = State.Harvested; // Update state

    items[_upc] = newItem; // Add new Item

    emit Harvested(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) public

  onlyFarmer

  harvested(_upc) //check if upc passed to previous stage

  verifyCaller(items[_upc].originFarmerID) //verify farmer is caller or not
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Processed;

    emit Processed(_upc);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public

  onlyFarmer

  processed(_upc) //check if upc is checked at previous stage

  verifyCaller(items[_upc].originFarmerID) //Accessibility to farmer only
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Packed;

    emit Packed(_upc);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public

  onlyFarmer

  packed(_upc)

  verifyCaller(items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.ForSale;
    existingItem.productPrice = _price;

    emit ForSale(_upc);
  }


  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  function buyItem(uint _upc) public payable

    onlyDistributor

    forSale(_upc) // check the product is already listed on sale or not

    paidEnough(items[_upc].productPrice) //check distributor's balance to buy product

    checkValueForDistributor(_upc) // Return the excess ether
    {

    Item storage existingItem = items[_upc];
    existingItem.ownerID = msg.sender;
    existingItem.itemState = State.Sold;
    existingItem.distributorID = msg.sender;

    // Transfer money to farmer
    uint productPrice = items[_upc].productPrice;
    items[_upc].originFarmerID.transfer(productPrice);

    emit Sold(_upc);
  }


  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  function shipItem(uint _upc) public

    onlyDistributor

    sold(_upc) //check the product is in sold state or not

    verifyCaller(items[_upc].distributorID) //caller verification
    {

    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Shipped;

    emit Shipped(_upc);
  }


  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  function receiveItem(uint _upc) public

    onlyRetailer

    shipped(_upc) //check the product is already shipped or not

    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    Item storage existingItem = items[_upc];
    existingItem.ownerID = msg.sender;
    existingItem.itemState = State.Received;
    existingItem.retailerID = msg.sender;

    emit Received(_upc);
  }


  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  function purchaseItem(uint _upc) public payable

    onlyConsumer

    received(_upc)

    paidEnough(items[_upc].productPrice) // Make sure paid enough

    checkValueForConsumer(_upc) //Return the excess ether
    {

      Item storage existingItem = items[_upc];
      existingItem.ownerID = msg.sender;
      existingItem.itemState = State.Purchased;
      existingItem.consumerID = msg.sender;

      emit Purchased(_upc);
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string  memory originFarmName,
  string  memory originFarmInformation,
  string  memory originFarmLatitude,
  string  memory originFarmLongitude
  )
  {
  // Assign values to the 8 parameters
  Item memory existingItem = items[_upc];

  itemSKU = existingItem.sku;
  itemUPC = existingItem.upc;
  ownerID = existingItem.ownerID;
  originFarmerID = existingItem.originFarmerID;
  originFarmName = existingItem.originFarmName;
  originFarmInformation = existingItem.originFarmInformation;
  originFarmLatitude = existingItem.originFarmLatitude;
  originFarmLongitude = existingItem.originFarmLongitude;

  return
  (
  itemSKU,
  itemUPC,
  ownerID,
  originFarmerID,
  originFarmName,
  originFarmInformation,
  originFarmLatitude,
  originFarmLongitude
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string  memory productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  )
  {
    // Assign values to the 9 parameters
  Item memory existingItem = items[_upc];
  itemSKU = existingItem.sku;
  itemUPC = existingItem.upc;
  productID = existingItem.productID;
  productNotes = existingItem.productNotes;
  productPrice = existingItem.productPrice;
  itemState = uint(existingItem.itemState);
  distributorID = existingItem.distributorID;
  retailerID = existingItem.retailerID;
  consumerID = existingItem.consumerID;

  return
  (
  itemSKU,
  itemUPC,
  productID,
  productNotes,
  productPrice,
  itemState,
  distributorID,
  retailerID,
  consumerID
  );
  }

}
