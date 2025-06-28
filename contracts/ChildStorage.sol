// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ChildStorage {
    struct DataEntry {
        string data; // Nội dung chuỗi
        string dataType; // Loại dữ liệu
        uint256 timestamp; // Thời gian (luôn lưu block.timestamp)
        uint8 rating; // Đánh giá (0-5, 0 nếu không có)
    }

    mapping(uint256 => DataEntry) public dataStore;
    uint256 public dataCount;
    uint256 public constant MAX_DATA = 1000;
    address public masterContract;

    modifier onlyMaster() {
        require(msg.sender == masterContract, "Only Master Contract can call");
        _;
    }

    constructor(address _masterContract) {
        masterContract = _masterContract;
        dataCount = 0;
    }

    function storeData(
        uint256 id,
        string memory data,
        string memory dataType,
        uint256 timestamp,
        uint8 rating
    ) external onlyMaster {
        require(dataCount < MAX_DATA, "Storage is full");
        require(bytes(data).length <= 1000, "Data too long");
        require(bytes(dataType).length <= 50, "Data type too long");
        require(rating <= 5, "Invalid rating");
        dataStore[id] = DataEntry(data, dataType, timestamp, rating);
        dataCount++;
    }

    function isFull() external view returns (bool) {
        return dataCount >= MAX_DATA;
    }

    function getData(uint256 id) external view returns (string memory, string memory, uint256, uint8) {
        DataEntry memory entry = dataStore[id];
        require(bytes(entry.data).length > 0, "Data not found");
        return (entry.data, entry.dataType, entry.timestamp, entry.rating);
    }
}