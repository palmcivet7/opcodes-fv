/*
*   Verification of GasBadNftMarketplace
*/
// Everytime storage is updated, we should emit an event. Therefore we should be using formal verification to check this.

using GasBadNftMarketplace as gasBadNftMarketplace;
using NftMarketplace as nftMarketplace;

/*//////////////////////////////////////////////////////////////
                                METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getListing(address nftAddress, uint256 tokenId) external  returns (INftMarketplace.Listing) envfree;
    function getProceeds(address seller) external  returns (uint256) envfree;
    // DISPATCHER(true) means safeTransferFrom can only do what any safeTransferFrom does in any of the known contracts
    // "Use nftMock.safeTransferFrom for all safeTransferFrom calls"
    function _.safeTransferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.onERC721Received(address, address, uint256, bytes) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                        GHOST VARIABLES
//////////////////////////////////////////////////////////////*/
ghost mathint g_listingUpdatesCount {
    // init_state = initial state will be 0
    // axiom = require such to be true
    // if we dont set this, the ghost variables will be havoced 
    init_state axiom g_listingUpdatesCount == 0;
}
ghost mathint g_log4Count {
    init_state axiom g_log4Count == 0;
}
// persistent ghost type name;
// `persistent` means ghost variables wont be havoced - but this means we are ignoring potential storage writes/sstores
// from external calls if we used it in this scenario

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
// `GasBadNftMarketplace::s_listings` mapping has `nftAddress` and `tokenId` as params
// s_listings returns a struct containing uint256 price and address seller -
// it doesnt matter which one we use in this circumstance because they will both be updated at same time
// and we just want to read the times storage was updated for this storage variable
//
// what a hook does, is it hooks on to any opcode such as sstore or sload etc
// so we pass it the variable associated with that opcode
hook Sstore s_listings[KEY address nftAddress][KEY uint256 tokenId].price uint256 price {
    // everytime the sstore opcode executes, our ghost variable is updated by 1
    g_listingUpdatesCount = g_listingUpdatesCount + 1;
}

// counting how many times the LOG4 opcode is executed
// LOG4 opcode: Append log record with four topics
hook LOG4(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4) {
    g_log4Count = g_log4Count + 1;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// certoraRun ./certora/conf/GasBad.conf --optimistic_fallback  
invariant anytime_mapping_updated_emit_event()
    g_listingUpdatesCount <= g_log4Count;

// if we call any function in nft marketplace or gasbad marketplace, we end up with the same resulting state
// this will be a parametric rule
rule calling_any_function_should_result_in_each_contract_having_the_same_state(method f, method f2) {
    // 1. Going to call the same function on NftMarketplace and GasBad
    // 2. Compare the getter functions of both to conclude they are the same
    // Note: running this will result in sanity checks because of our "rule_sanity": "basic", .conf configuration
    // Setting "rule_sanity": "none", will run without the sanity checks that look at the wrong function comparisons

    // Arrange
    require(f.selector == f2.selector);
    env e;
    calldataarg args;
    // f(e, args); // same as currentContract.f(e, args);
    address listingAddress;
    uint256 tokenId;
    address seller;

    require(gasBadNftMarketplace.getProceeds(e, seller) == nftMarketplace.getProceeds(e, seller));
    require(gasBadNftMarketplace.getListing(e, listingAddress, tokenId).price == nftMarketplace.getListing(e, listingAddress, tokenId).price);
    require(gasBadNftMarketplace.getListing(e, listingAddress, tokenId).seller == nftMarketplace.getListing(e, listingAddress, tokenId).seller);

    // Act
    gasBadNftMarketplace.f(e, args);
    nftMarketplace.f2(e, args);

    // Assert
    assert(gasBadNftMarketplace.getProceeds(e, seller) == nftMarketplace.getProceeds(e, seller));
    assert(gasBadNftMarketplace.getListing(e, listingAddress, tokenId).price == nftMarketplace.getListing(e, listingAddress, tokenId).price);
    assert(gasBadNftMarketplace.getListing(e, listingAddress, tokenId).seller == nftMarketplace.getListing(e, listingAddress, tokenId).seller);

}


// // example with filter
// rule example_rule_with_filter_name(method f) filtered{
//     // filter body
//     f.selector == "0x13455223";
// } {
//     // function rule body
//     // filter works similar to:
//     // require(f.selector == "0x13455223");
// }