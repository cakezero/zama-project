// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
import { FHE, euint32, externalEuint32, euint256, euint64 } from "@fhevm/solidity/lib/FHE.sol";

contract PointsGame is SepoliaConfig {
    struct RoomInfo {
        string player1;
        euint32 player1Number;
        string player2;
        euint32 player2Number;
    }

    struct TopWinner {
        string name;
        address user;
        euint256 points;
    }

    // mapping (address => euint256) private leaderboard;
    // mapping (euint256 => generatedNumbers) private answers;
    mapping (string => RoomInfo) private roomDetails;

    TopWinner public _topWinner;
    mapping (address => euint256) private gamesPlayed;
    mapping (address => euint256) private totalPointsGottenFromGames;
    mapping (address => euint32[]) private userNumbers;
    mapping (address => euint256) private userPoints;
    mapping (address => euint32[]) private userResults;

    event NumberSaved(string msg);
    error OnlyFiveQuestionsCanBeAnswered;

    function getRandomNumber(euint32 loopCounter, euint32 _lowerBound, euint64 seed) internal returns euint32 {

        euint256 rand = euint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    seed,
                    loopCounter
                )
            )
        );

        // Range 0–9, 10–19, 20–29, etc
        euint32 randomNumber = (rand % 10) + _lowerBound;
        return randomNumber;
    }

    function addPlayersNumbers(externalEuint32 player1Number, externalEuint32 player2Number, bytes calldata inputProof, string memory roomId, string memory player1Name, string memory player2Name) external {
        euint32 encryptedPlayer1Number = FHE.fromExternal(player1Number, inputProof);
        euint32 encryptedPlayer2Number = FHE.fromExternal(player2Number, inputProof);

        // Store in roomDetails mapping
        roomDetails[roomId] = RoomInfo({
            player1: player1Name,
            player2: player2Name,
            player1Number: encryptedPlayer1Number,
            player2Number: encryptedPlayer2Number
        });

        // Set access control permissions
        FHE.allowThis(roomDetails[roomId]);
        FHE.allow(roomDetails[roomId], msg.sender);

        emit GottenPlayersNumbers("Player 1 and 2 numbers saved!");
    }

    function AddNumber(externalEuint32 userNumber, bytes calldata inputProof) external {
        euint32 encryptedUserNumber = FHE.fromExternal(userNumber, inputProof);

        if (userNumbers[msg.sender].length == 5) revert OnlyFiveQuestionsCanBeAnswered();

        userNumbers[msg.sender].push(encryptedUserNumber);

        FHE.allowThis(userNumbers[msg.sender]);
        FHE.allow(userNumbers[msg.sender], msg.sender);

        emit NumberSaved("Player number saved!");
    }

    /// @notice This returns the last result from the desired user
    /// @param _user The address whose result is to be fetched
    function getAnotherPlayerResult(address _user) public view returns (euint32[] player, euint32[] system) {
        player = userNumbers[_user];
        system = userResults[_user];
    }

    function getResult(string memory username) public view returns (euint32[] playerNumbers, euint32[] systemNumbers, euint256 points, euint256 totalPoints) {
        euint64 seed = gamesPlayed[msg.sender];
        playerNumbers = userNumbers[msg.sender];
        points = 0;

        euint32 number1 = getRandomNumber(i, 0 * 10, seed);
        userResults[msg.sender].push(number1);

        if (number1 == playerNumbers[0]) {
            points = points + 10;
        }

        euint32 number2 = getRandomNumber(i, 1 * 10, seed + 4);
        userResults[msg.sender].push(number2);

        if (number2 == playerNumbers[1]) {
            points = points + 10;
        }

        euint32 number3 = getRandomNumber(i, 2 * 10, seed + 8);
        userResults[msg.sender].push(number3);

        if (number3 == playerNumbers[2]) {
            points = points + 10;
        }

        euint32 number4 = getRandomNumber(i, 3 * 10, seed + 12);
        userResults[msg.sender].push(number4);

        if (number4 == playerNumbers[3]) {
            points = points + 10;
        }

        euint32 number5 = getRandomNumber(i, 4 * 10, seed + 16);
        userResults[msg.sender].push(number5);

        if (number5 == playerNumbers[4]) {
            points = points + 10;
        }

        totalPoints = totalPointsGottenFromGames[msg.sender] + points;

        if (totalPoints > _topWinner.points) {
            _topWinner = TopWinner({
                name: username,
                user: msg.sender,
                points: totalPoints
            });
        }

        systemNumbers = userResults[msg.sender];
        totalPointsGottenFromGames[msg.sender] = totalPoints;
        gamesPlayed[msg.sender]++;
    }

    // /// @notice A restricted function that only a user who has added a record can call
    // function fetchRecord() public view returns (Record memory) {
    //     return records[msg.sender];
    // }
}
