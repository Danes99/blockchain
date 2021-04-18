pragma solidity ^0.6.12;

// SPDX-License-Identifier: GPL-3.0

import "./Ownable.sol";
import "./SafeMath.sol";

contract Election is Ownable {

using SafeMath for uint256;

    // Constants
    address constant nullAdress = address(0);

    // Model a Participant
    struct Participant {

        uint256 id;
        string name;
        bool hasVoted;
        
        // Team info
        // string status;
        address teamAddress;
    }

    // Model a Team
    struct Team {

        uint256 id;
        string name;
        bool isVotable;
        uint voteCount;
        
        // Team members
        address memberSecretary;
        address memberTresury;
        
        bool hasMemberSecretaryJoined;
        bool hasMemberTresuryJoined;
    }

    // Election status
    bool public hasElectionStarted;
    bool public isElectionRunning;
    
    // Counters
    uint public participantsCount;
    uint public teamsCount;
    
    // List of participants & teams
    mapping(address => Participant) public participants;
    mapping(address => Team) public teams;

    // Voted event
    event votedEvent ( address indexed _address);

    function runElection (bool _status) public onlyOwner {

        if (!hasElectionStarted && _status) {
            hasElectionStarted = true;
        }

        isElectionRunning = _status;
    }

    function createParticipant (address _address, string memory _name) public onlyOwner {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // Must not be in participants
        require(participants[_address].id == 0, "Target already is participant");

        // Increment counter
        participantsCount ++;

        // Add new participant
        participants[_address] = Participant(
            participantsCount, 
            _name, 
            false, 
            // "",
            nullAdress
        );
    }

    function deleteParticipant (address _address) public onlyOwner {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // Target must be in participants
        require(participants[_address].id != 0, "Target must be participant");
        
        // If participant is a team president
        if (teams[_address].id != 0) {
            
            // Update team members (they are no longer part the team)
            participants[ teams[_address].memberSecretary ].teamAddress = nullAdress;
            participants[ teams[_address].memberTresury ].teamAddress = nullAdress;
            
            // Remove team associated with participant address (president)
            teamsCount --;
            delete teams[_address];
        }
        
        
        // If participant is a team member
        address teamAddress = participants[_address].teamAddress;
        
        if ( teamAddress != nullAdress ) {
            
            if ( teams[teamAddress].memberSecretary == _address ) {
                
                teams[teamAddress].memberSecretary = nullAdress;
                teams[teamAddress].hasMemberSecretaryJoined = false;
            } 
            else if ( teams[teamAddress].memberTresury == _address ) {
                
                teams[teamAddress].memberTresury = nullAdress;
                teams[teamAddress].hasMemberTresuryJoined = false;
            }
        }
        
        // Remove participant
        participantsCount --;
        delete participants[_address];
    }

    function createTeam (string memory _name) public {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // Must be in participants
        require(participants[msg.sender].id != 0, "You must be participant");
        
        // Cannot create team if already created one
        require(teams[msg.sender].id == 0, "Already created a team");
        
        // Increment counter
        teamsCount ++;

        // Add new participant in the array
        teams[msg.sender] = Team(
            teamsCount, 
            _name, 
            false, 
            0,
            nullAdress,
            nullAdress,
            false,
            false
        );
        
        // Update team address
        participants[msg.sender].teamAddress = msg.sender;
    }
    
    function createTeamMember (address _address, uint _status) public {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // President has to be in participants
        // require(participants[msg.sender].id != 0, "You must be participant");
        
        // Sender must have created a team
        require(teams[msg.sender].id != 0, "You must have created a team");
        
        // Target must be in participants
        require(participants[_address].id != 0, "Target must be participant");
        
        // Target cannot be president
        require(teams[_address].id == 0, "Target already is president");
        
        // Is team member status ok?
        require(_status > 0 && _status < 3, "Wrong status");
        
        if (_status == 1) {
            teams[msg.sender].memberSecretary = _address;
            teams[msg.sender].hasMemberSecretaryJoined = false;
        } 
        else if (_status == 2) {
            teams[msg.sender].memberTresury = _address;
            teams[msg.sender].hasMemberTresuryJoined = false;
        }
        
        
    }

    function joinTeam (address _address, uint _status) public {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // Sender must not have created a team
        require(teams[msg.sender].id == 0, "You must not have created a team");
        
        // Sender must not be in a team
        require(participants[msg.sender].teamAddress == nullAdress, "You must not be in a team");
        
        // Team address must exist
        require(teams[_address].id != 0, "No teams with this address");
        
        // Is team member status ok?
        require(_status > 0 && _status < 3, "Wrong status");
        
        // Team member must not be attributed
        bool teamMemberStatus = _status == 1 ? teams[_address].hasMemberSecretaryJoined : teams[_address].hasMemberTresuryJoined;
        require(!teamMemberStatus , "Team member is already attributed");
        
        // Sender must have been invited
        address teamMemberAddress = _status == 1 ? teams[_address].memberSecretary : teams[_address].memberTresury;
        require(teamMemberAddress == msg.sender , "You must have been invited to join the team");
        
        // Update Team
        if (_status == 1) {
            teams[_address].hasMemberSecretaryJoined = true;
        } 
        else if (_status == 2) {
            teams[_address].hasMemberTresuryJoined = true;
        }
        
        // Update participant
        participants[msg.sender].teamAddress = _address;
        
        // Update team state
        updateTeamIsVotable(_address);
    }
    
    function updateTeamPresident (address _address) public {
        
        // Election must not have started
        require(!hasElectionStarted, "Election has already started");
        
        // Sender must have created a team
        require(teams[msg.sender].id != 0, "You must have created a team");
        
        // Target must be in participants
        require(participants[_address].id != 0, "Target must be participant");
        
        // Target cannot be president
        require(teams[_address].id == 0, "Target already is president");
        
        // Target cannot be team member
        require(participants[_address].teamAddress == nullAdress, "Target must not be team member");
        
        // Duplicate sender's team to receiver address
        teams[_address] = teams[msg.sender];
        
        // Update Member: secretary
        address memberSecretary = teams[msg.sender].memberSecretary;
        if (memberSecretary != nullAdress) {
            participants[memberSecretary].teamAddress = _address;
        }
        
        // Member: tresury
        address memberTresury = teams[msg.sender].memberTresury;
        if (memberTresury != nullAdress) {
            participants[memberTresury].teamAddress = _address;
        }
        
        // Update member: former president
        participants[msg.sender].teamAddress = nullAdress;
        
        // Update member: new president
        participants[_address].teamAddress = _address;
        
        // Delete former team
        delete teams[msg.sender];
    }

    function vote (address _address) public {
        
        // Election must have started
        require(hasElectionStarted, "Election has not started yet");
        
        // Election must be running
        require(isElectionRunning, "Election is not running");
        
        // Require that they haven't voted before
        require(!participants[msg.sender].hasVoted, "You have already voted");

        // Require a valid team address
        require(teams[_address].id != 0, "Require valid address");
        
        // Team must be votable
        require(teams[_address].isVotable, "Team is not votable");

        // Record that participant has voted
        participants[msg.sender].hasVoted = true;

        // Update team vote Count
        teams[_address].voteCount ++;

        // Trigger voted event
        emit votedEvent (_address);
    }
    
    function updateTeamIsVotable(address _address) private {
        
        Team memory team = teams[_address];
        bool isVotable = team.hasMemberSecretaryJoined && team.hasMemberTresuryJoined;
        
        if ( team.isVotable != isVotable ) {
            teams[_address].isVotable = isVotable;
        }
    }
}
