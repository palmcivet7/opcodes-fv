/*
    Verification of Challenge
*/

methods {
    function challengeExp(uint256) external returns (uint256) envfree;
    function helperExp(uint256) external returns (uint256);
}

rule challengeExpMatchesHelperExp(uint256 x) {
    env e;
    require(e.msg.value == 0);

    assert(challengeExp(x) == helperExp(e, x));
}