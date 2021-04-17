pragma solidity ^0.6.12;

// SPDX-License-Identifier: GPL-3.0

import "./Ownable.sol";
import "./SafeMath.sol";

contract Election is Ownable {

using SafeMath for uint256;

    // Model a Participant
    struct Participant {

        uint256 id;
        string name;
        bool hasVoted;
        string status;
    }

    // Model a Team
    struct Team {

        uint256 id;
        string name;
        bool isVotable;
        uint voteCount;
    }

    // Election status
    bool public hasElectionStarted;
    bool public isElectionRunning;
    
    // Counters
    uint public teamsCount;
    uint public participantsCount;
    
    // Store list of participants
    mapping(address => Participant) public participants;
    
    // Store list of teams
    mapping(address => Team) public teams;

    // Voted event
    event votedEvent ( uint indexed _candidateId);

    function runElection (bool _status) public onlyOwner {

        if (!hasElectionStarted && _status) {
            hasElectionStarted = true;
        }

        isElectionRunning = _status;
    }

    function createParticipant (address _address, string memory _name) public onlyOwner {
        
        // Cannot add participant if election started 
        require(!hasElectionStarted);

        // Increment counter
        participantsCount ++;

        // Add new participant in the array
        participants[_address] = Participant(
            participantsCount, 
            _name, 
            false, 
            ""
        );
    }

    function deleteParticipant (address _address) public onlyOwner {


    }
    
    function createTeamTest () public view returns(uint) {
        
        // Must be in participants
        return participants[msg.sender].id;
        
    }
    
    

    function createTeam (string memory _name) public {
        
        // Must be in participants
        require(participants[msg.sender].id != 0, "Must be participant");
        
        // Cannot create team if already created one
        require(teams[msg.sender].id == 0, "Already created a team");
        
        // Increment counter
        teamsCount ++;

        // Add new participant in the array
        teams[msg.sender] = Team(
            teamsCount, 
            _name, 
            false, 
            0
        );
        
    }

    function joinTeam (string memory _id) public {

    }

    /*function createMember (address memory _address) public {

    }*/

    /*function vote (uint _candidateId) public {
        
        // Require that they haven't voted before
        require(!voters[msg.sender]);

        // Require a valid team id
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // Record that participant has voted
        voters[msg.sender] = true;

        // Update team vote Count
        candidates[_candidateId].voteCount ++;

        // Trigger voted event
        emit votedEvent (_candidateId);
    }*/
}
