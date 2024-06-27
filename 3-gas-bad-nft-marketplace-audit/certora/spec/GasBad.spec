/*
*   Verification of GasBadNftMarketplace
*/

// Everytime storage is updated, we should emit an event. Therefore we should be using formal verification to check this.

/*//////////////////////////////////////////////////////////////
                                METHODS
//////////////////////////////////////////////////////////////*/
methods {
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