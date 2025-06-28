// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ChildStorage.sol";

contract MasterStorage {
    mapping(uint256 => address) public childContracts; // Danh sách Child Contracts
    mapping(uint256 => address) public dataToChild; // Ánh xạ dataId -> Child Contract
    mapping(string => uint256[]) public dataTypeToIds; // Ánh xạ dataType -> danh sách dataId
    mapping(uint8 => uint256[]) public ratingToIds; // Ánh xạ rating -> danh sách dataId
    mapping(uint256 => uint256[]) public timeToIds; // Ánh xạ timestamp (làm tròn theo ngày) -> danh sách dataId
    mapping(bytes32 => uint256) public dataHashToId; // Ánh xạ hash(data) -> dataId
    uint256 public childCount;
    uint256 public dataIdCounter;
    address public owner;
    uint256 public constant MAX_CHILD_CONTRACTS = 100;

    event DataStored(
        uint256 indexed id,
        string data,
        string indexed dataType,
        uint256 indexed timestamp,
        uint8 rating,
        address childContract
    );
    event NewChildContract(address indexed childAddress, uint256 childIndex);

    constructor() {
        owner = msg.sender;
        childCount = 0;
        dataIdCounter = 0;
        createNewChildContract();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    function createNewChildContract() internal returns (address) {
        require(childCount < MAX_CHILD_CONTRACTS, "Max child contracts reached");
        ChildStorage newChild = new ChildStorage(address(this));
        childContracts[childCount] = address(newChild);
        emit NewChildContract(address(newChild), childCount);
        childCount++;
        return address(newChild);
    }

    function storeData(
        string memory data,
        string memory dataType,
        uint8 rating
    ) external onlyOwner {
        require(bytes(data).length > 0, "Data cannot be empty");
        require(bytes(dataType).length > 0, "Data type cannot be empty");
        require(rating <= 5, "Invalid rating");

        ChildStorage currentChild = ChildStorage(childContracts[childCount - 1]);
        if (currentChild.isFull()) {
            currentChild = ChildStorage(createNewChildContract());
        }

        // Lưu dữ liệu với timestamp tự động
        uint256 timestamp = block.timestamp;
        currentChild.storeData(dataIdCounter, data, dataType, timestamp, rating);
        dataToChild[dataIdCounter] = address(currentChild);

        // Lưu ánh xạ
        dataTypeToIds[dataType].push(dataIdCounter);
        if (rating > 0) {
            ratingToIds[rating].push(dataIdCounter);
        }
        uint256 dayTimestamp = block.timestamp / 1 days;
        timeToIds[dayTimestamp].push(dataIdCounter);
        bytes32 dataHash = keccak256(abi.encodePacked(data));
        dataHashToId[dataHash] = dataIdCounter;

        emit DataStored(dataIdCounter, data, dataType, timestamp, rating, address(currentChild));
        dataIdCounter++;
    }

    function getData(uint256 id) external view returns (string memory, string memory, uint256, uint8) {
        ChildStorage child = ChildStorage(dataToChild[id]);
        require(address(child) != address(0), "Data not found");
        return child.getData(id);
    }

    function getLatestData(uint256 limit, uint256 offset, string memory dataType) external view returns (
        uint256[] memory ids,
        string[] memory data,
        string[] memory dataTypes,
        uint256[] memory timestamps,
        uint8[] memory ratings
    ) {
        uint256[] memory idList = dataTypeToIds[dataType];
        require(offset <= idList.length, "Offset out of bounds");
        uint256 count = idList.length - offset > limit ? limit : idList.length - offset;
        
        ids = new uint256[](count);
        data = new string[](count);
        dataTypes = new string[](count);
        timestamps = new uint256[](count);
        ratings = new uint8[](count);

        // Lấy từ ID mới nhất (cuối danh sách) với offset
        for (uint256 i = 0; i < count; i++) {
            ids[i] = idList[idList.length - 1 - offset - i];
            ChildStorage child = ChildStorage(dataToChild[ids[i]]);
            (data[i], dataTypes[i], timestamps[i], ratings[i]) = child.getData(ids[i]);
        }
        return (ids, data, dataTypes, timestamps, ratings);
    }

    function getDataByRating(uint8 rating, uint256 limit, uint256 offset) external view returns (
        uint256[] memory ids,
        string[] memory data,
        string[] memory dataTypes,
        uint256[] memory timestamps,
        uint8[] memory ratings
    ) {
        require(rating <= 5, "Invalid rating");
        uint256[] memory idList = ratingToIds[rating];
        require(offset <= idList.length, "Offset out of bounds");
        uint256 count = idList.length - offset > limit ? limit : idList.length - offset;

        ids = new uint256[](count);
        data = new string[](count);
        dataTypes = new string[](count);
        timestamps = new uint256[](count);
        ratings = new uint8[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = idList[offset + i];
            ChildStorage child = ChildStorage(dataToChild[ids[i]]);
            (data[i], dataTypes[i], timestamps[i], ratings[i]) = child.getData(ids[i]);
        }
        return (ids, data, dataTypes, timestamps, ratings);
    }

    function getDataByType(string memory dataType, uint256 limit, uint256 offset) external view returns (
        uint256[] memory ids,
        string[] memory data,
        string[] memory dataTypes,
        uint256[] memory timestamps,
        uint8[] memory ratings
    ) {
        uint256[] memory idList = dataTypeToIds[dataType];
        require(offset <= idList.length, "Offset out of bounds");
        uint256 count = idList.length - offset > limit ? limit : idList.length - offset;
        
        ids = new uint256[](count);
        data = new string[](count);
        dataTypes = new string[](count);
        timestamps = new uint256[](count);
        ratings = new uint8[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = idList[offset + i];
            ChildStorage child = ChildStorage(dataToChild[ids[i]]);
            (data[i], dataTypes[i], timestamps[i], ratings[i]) = child.getData(ids[i]);
        }
        return (ids, data, dataTypes, timestamps, ratings);
    }

    function getDataByHash(bytes32 dataHash) external view returns (string memory, string memory, uint256, uint8) {
        uint256 id = dataHashToId[dataHash];
        ChildStorage child = ChildStorage(dataToChild[id]);
        require(address(child) != address(0), "Data not found");
        return child.getData(id);
    }

    function getBatchData(uint256 startId, uint256 count) external view returns (
        string[] memory data,
        string[] memory dataTypes,
        uint256[] memory timestamps,
        uint8[] memory ratings
    ) {
        require(startId < dataIdCounter, "Invalid start ID");
        require(count > 0 && startId + count <= dataIdCounter, "Invalid count");

        data = new string[](count);
        dataTypes = new string[](count);
        timestamps = new uint256[](count);
        ratings = new uint8[](count);

        for (uint256 i = 0; i < count; i++) {
            ChildStorage child = ChildStorage(dataToChild[startId + i]);
            if (address(child) != address(0)) {
                (data[i], dataTypes[i], timestamps[i], ratings[i]) = child.getData(startId + i);
            }
        }
        return (data, dataTypes, timestamps, ratings);
    }

    function getChildCount() external view returns (uint256) {
        return childCount;
    }

    // Hàm phụ để lấy tổng số dữ liệu theo dataType
    function getDataTypeCount(string memory dataType) external view returns (uint256) {
        return dataTypeToIds[dataType].length;
    }

    // Hàm phụ để lấy tổng số dữ liệu theo rating
    function getRatingCount(uint8 rating) external view returns (uint256) {
        require(rating <= 5, "Invalid rating");
        return ratingToIds[rating].length;
    }
}
