// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { PausableWithAccessFake} from "test/fakes/PausableWithAccessFake.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract PausableWithAccess_Test is Common_Test {    
    event Paused(address account);

    event Unpaused(address account);

    PausableWithAccessFake pausableWithAccess;

    function setUp() public virtual override {
        super.setUp();

        pausableWithAccess = new PausableWithAccessFake(owner);

        vm.prank(owner);
        pausableWithAccess.grantRole(PAUSER_ROLE, pauser);
    }

    // ********* PausableWithAccess.sol functionality tests *********
    function test_pausedAfterPausing_succeeds() public {
        vm.expectEmit(true, true, true, true, address(pausableWithAccess));
        emit Paused(pauser);
        
        vm.prank(pauser);
        pausableWithAccess.pause();
        assertEq(pausableWithAccess.paused(), true);
    }

    function test_pausingAfterPaused_reverts() external {
        vm.prank(pauser);
        pausableWithAccess.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(pauser);
        pausableWithAccess.pause();
    }

    function test_unpausedAfterUnpausing_succeeds() external {
        vm.prank(pauser);
        pausableWithAccess.pause();
        
        vm.prank(pauser);
        pausableWithAccess.unpause();
        assertEq(pausableWithAccess.paused(), false);
    }

    function test_nonPauserPausing_reverts() external{
        vm.prank(owner);
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(owner),
            " is missing role ",
            roleToString(PAUSER_ROLE)
        )));
        pausableWithAccess.pause();
    }

    function test_nonPauserUnpausing_reverts() external{
        vm.prank(pauser);
        pausableWithAccess.pause();

        vm.prank(owner);
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(owner),
            " is missing role ",
            roleToString(PAUSER_ROLE)
        )));
        pausableWithAccess.unpause();
    }

    function test_notPausedOnInitialize_succeeds() external {
        assertEq(pausableWithAccess.paused(), false);
    }

    function test_changingPauser_succeeds() external {
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(PAUSER_ROLE, alice, owner);

        vm.prank(owner);
        pausableWithAccess.grantRole(PAUSER_ROLE, alice);
        assertEq(pausableWithAccess.hasRole(PAUSER_ROLE, alice), true);
    }

    function test_nonAdminChangingPauser_reverts() external {
        vm.expectRevert(bytes(string.concat(
            "AccessControl: account ",
            addressToString(blacklister),
            " is missing role ",
            roleToString(pausableWithAccess.DEFAULT_ADMIN_ROLE())
        )));
        vm.prank(address(blacklister));
        pausableWithAccess.grantRole(PAUSER_ROLE, address(alice));
    }
}