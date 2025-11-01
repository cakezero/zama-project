// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
import { FHE, euint8, euint32, eaddress, externalEuint8, ebool, euint128, euint64 } from "@fhevm/solidity/lib/FHE.sol";

contract PointsGame is SepoliaConfig {
    // struct RoomInfo {
    //     string player1;
    //     euint8 player1Number;
    //     string player2;
    //     euint8 player2Number;
    // }

    struct TopWinner {
        string name;
        address user;
        euint128 points;
    }

    // mapping (address => euint256) private leaderboard;
    // mapping (euint256 => generatedNumbers) private answers;
    // mapping (string => RoomInfo) private roomDetails;

    TopWinner public _topWinner;
    mapping (address => euint64) private gamesPlayed;
    mapping (address => euint128) private totalPointsGottenFromGames;
    mapping (address => euint8[]) private userNumbers;
    mapping (address => euint128) private userPoints;
    mapping (address => euint8[]) private userResults;

    event NumberSaved(string msg);
    event GottenPlayersNumbers(string msg);
    error OnlyFiveQuestionsCanBeAnswered();
    error OnlyPlayersWithStoredNumbersCanCallThisFunction();

    function getRandomNumber(euint8 _lowerBound) internal returns (euint8) {
        euint8 randomNumber = FHE.randEuint8(10);

        return FHE.add(randomNumber, _lowerBound);
    }

    // function addPlayersNumbers(
    //     externalEuint8 player1Number,
    //     externalEuint8 player2Number,
    //     bytes calldata inputProof,
    //     string memory roomId,
    //     string memory player1Name,
    //     string memory player2Name
    // ) external {
    //     euint8 encryptedPlayer1Number = FHE.fromExternal(player1Number, inputProof);
    //     euint8 encryptedPlayer2Number = FHE.fromExternal(player2Number, inputProof);

    //     // Store in roomDetails mapping
    //     roomDetails[roomId] = RoomInfo({
    //         player1: player1Name,
    //         player2: player2Name,
    //         player1Number: encryptedPlayer1Number,
    //         player2Number: encryptedPlayer2Number
    //     });

    //     // Set access control permissions
    //     FHE.allowThis(roomDetails[roomId]);
    //     FHE.allow(roomDetails[roomId], msg.sender);

    //     emit NumberSaved("Player 1 and 2 numbers saved!");
    // }

    function AddNumber(externalEuint8 userNumber, bytes calldata inputProof) external {
        euint8 encryptedUserNumber = FHE.fromExternal(userNumber, inputProof);

        uint256 userNumbersLength = userNumbers[msg.sender].length;

        if (userNumbersLength == 5) revert OnlyFiveQuestionsCanBeAnswered();

        userNumbers[msg.sender][userNumbersLength] = encryptedUserNumber;

        FHE.allowThis(userNumbers[msg.sender][userNumbersLength]);
        FHE.allow(userNumbers[msg.sender][userNumbersLength], msg.sender);

        emit NumberSaved("single player number saved!");
    }

    /// @notice This returns the last result from the desired user
    // change this to use gameId
    /// @param _user The address whose result is to be fetched
    function getAnotherPlayerResult(address _user) public view returns (euint8[] memory player, euint8[] memory system) {
        player = userNumbers[_user];
        system = userResults[_user];
    }

    function getResult(string memory username) public returns (euint8[] memory playerNumbers, euint8[] memory systemNumbers, euint128 points, euint128 totalPoints) {
        uint256 userResultLength = userResults[msg.sender].length;

        playerNumbers = userNumbers[msg.sender];
        points = FHE.asEuint128(0);

        euint8 number1 = getRandomNumber(FHE.asEuint8(0 * 10));
        userResults[msg.sender][userResultLength] = number1;

        points = FHE.select(FHE.eq(number1, playerNumbers[0]), FHE.add(points, FHE.asEuint128(10)), points);

        euint8 number2 = getRandomNumber(FHE.asEuint8(1 * 10));
        userResults[msg.sender][userResultLength + 1] = number2;

        points = FHE.select(FHE.eq(number2, playerNumbers[1]), FHE.add(points, FHE.asEuint128(10)), points);

        euint8 number3 = getRandomNumber(FHE.asEuint8(2 * 10));
        userResults[msg.sender][userResultLength + 2] = number3;

        points = FHE.select(FHE.eq(number3, playerNumbers[2]), FHE.add(points, FHE.asEuint128(10)), points);

        euint8 number4 = getRandomNumber(FHE.asEuint8(3 * 10));
        userResults[msg.sender][userResultLength + 3] = number4;

        points = FHE.select(FHE.eq(number4, playerNumbers[3]), FHE.add(points, FHE.asEuint128(10)), points);

        euint8 number5 = getRandomNumber(FHE.asEuint8(4 * 10));
        userResults[msg.sender][userResultLength + 4] = number5;

        points = FHE.select(FHE.eq(number5, playerNumbers[4]), FHE.add(points, FHE.asEuint128(10)), points);

        totalPoints = FHE.add(totalPointsGottenFromGames[msg.sender], points);

        euint128 topWinnerPoints = FHE.select(FHE.gt(totalPoints, _topWinner.points), totalPoints, _topWinner.points);
        // string memory topWinnerUsername = FHE.select(FHE.gt(totalPoints, _topWinner.points), username, _topWinner.name);
        eaddress encTopWinnerAddress = FHE.select(FHE.gt(totalPoints, _topWinner.points), FHE.asEaddress(msg.sender), FHE.asEaddress(_topWinner.user));

        gamesPlayed[msg.sender] = FHE.add(gamesPlayed[msg.sender], 1);
        userResults[msg.sender] = systemNumbers;
        totalPointsGottenFromGames[msg.sender] = totalPoints;
    }

    function clearNumbersAndResult() onlyPlayer external {

    }

    modifier onlyPlayer {
        if (userNumbers[msg.sender].length == 0) revert OnlyPlayersWithStoredNumbersCanCallThisFunction();
        _;
    }

    // /// @notice A restricted function that only a user who has added a record can call
    // function fetchRecord() public view returns (Record memory) {
    //     return records[msg.sender];
    // }
}
