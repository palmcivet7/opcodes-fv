/*
*   verification of NftMock
*/

methods {
    // Non-summary declarations: use the function as defined in the codebase
    function totalSupply() external returns(uint256) envfree;
    function mint() external;
    function balanceOf(address) external returns(uint256) envfree;
    // Sometimes the function is too complex
    // Sometimes the functions are only called by one or two contracts
    // Sometimes we want to make more assumptions for the prover to run
    // Summary declarations: make assumptions about the function
    // totalSupply will always return 1:
    // function totalSupply() external returns(uint256) => ALWAYS(1);
    // _.totalSupply() refers to the totalSupply() of any applicable contract (Wildcard function declaration)
    // function _.totalSupply() external returns(uint256) => ALWAYS(1);
    // currentContract._() refers to every single function in the currentContract (Catch-all entry declaration)
    // function currentContract._() external returns(uint256) => ALWAYS(1);

}

// invariant totalSupplyIsNotNegative()
//     totalSupply() >= 0;

rule minting_mints_one_nft() {
    // Arrange
    env e;
    address minter;
    require e.msg.value == 0;
    require e.msg.sender == minter;
    mathint balanceBefore = balanceOf(minter); // mathint instead of uint256 so doesnt overflow

    // Act
    currentContract.mint(e);

    // Assert
    assert to_mathint(balanceOf(minter)) == balanceBefore + 1, "Only 1 NFT should be minted";
}

// rule sanity {
//     method f;
//     env e;
//     calldataarg arg;
//     f(e, arg);
//     satisfy true;
// }

// see: parametric rule
// this is going to be a dummy rule that we expect to fail
// there is almost no difference defining a variable in a rule body vs in the input parameters
// rule no_change_total_supply(method f) {
//     // method f;
//     uint256 totalSupplyBefore = totalSupply();

//     env e;
//     calldataarg arg;
//     f(e, arg);

//     assert totalSupply() == totalSupplyBefore, "Total supply should not change";
// }