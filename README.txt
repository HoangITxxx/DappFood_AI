Hướng Dẫn Sử Dụng Smart Contract DappFood
Tổng Quan
MasterStorage.sol và ChildStorage.sol là hai Smart Contract được thiết kế cho DappFood để quản lý dữ liệu liên quan đến món ăn, đánh giá, và xếp hạng. Các tính năng chính:

Lưu trữ dữ liệu linh hoạt: nội dung (data), loại dữ liệu (dataType), thời gian (timestamp tự động), và xếp hạng (rating, tùy chọn từ 0-5).
Truy vấn nhanh: lấy danh sách món ăn hot, món ăn 5 sao, hoặc dữ liệu theo loại.
Hỗ trợ phân trang (limit, offset) để xử lý dữ liệu lớn, tránh vượt giới hạn gas.
Cung cấp danh sách dữ liệu để AI phân tích xu hướng hoặc đề xuất món ăn.

Hệ thống ưu tiên tốc độ truy vấn, chấp nhận chi phí gas cao, và khuyến nghị sử dụng chỉ mục off-chain để tối ưu hiệu suất.
Hướng Dẫn Sử Dụng
1. Lưu Trữ Dữ Liệu
Hàm storeData trong MasterStorage dùng để lưu dữ liệu.

Cú pháp:function storeData(string memory data, string memory dataType, uint8 rating) external onlyOwner

Tham số:
data: Nội dung chuỗi (ví dụ: "Phở bò", "Ngon tuyệt!").
dataType: Loại dữ liệu (ví dụ: "menu_item", "food_review").
rating: Xếp hạng từ 0-5 (0 nếu không có xếp hạng).

Tự động: timestamp được gán bằng block.timestamp.
Ví dụ:
Lưu món ăn: storeData("Phở bò", "menu_item", 0) → Lưu món ăn không có xếp hạng.
Lưu đánh giá: storeData("Ngon tuyệt!", "food_review", 5) → Lưu đánh giá 5 sao.

2. Truy Vấn Dữ Liệu
Các hàm truy vấn trả về danh sách dữ liệu (ids, data, dataTypes, timestamps, ratings) để AI phân tích.
a. Lấy Món Ăn Hot Gần Đây

Hàm: getLatestData
Cú pháp:function getLatestData(uint256 limit, uint256 offset, string memory dataType) external view returns (
    uint256[] memory ids,
    string[] memory data,
    string[] memory dataTypes,
    uint256[] memory timestamps,
    uint8[] memory ratings
)

Tham số:
limit: Số lượng tối đa phần tử trả về (ví dụ: 50).
offset: Vị trí bắt đầu (ví dụ: 0 để lấy từ mới nhất, 50 để bỏ qua 50 phần tử đầu).
dataType: Loại dữ liệu (ví dụ: "food_review").


Ví dụ:
getLatestData(50, 0, "food_review"): Lấy 50 đánh giá mới nhất.
getLatestData(50, 50, "food_review"): Lấy 50 đánh giá tiếp theo.


b. Lấy Món Ăn Theo Xếp Hạng

Hàm: getDataByRating
Cú pháp:function getDataByRating(uint8 rating, uint256 limit, uint256 offset) external view returns (
    uint256[] memory ids,
    string[] memory data,
    string[] memory dataTypes,
    uint256[] memory timestamps,
    uint8[] memory ratings
)


Tham số:
rating: Xếp hạng cần lấy (1-5).
limit, offset: Như trên.


Ví dụ:
getDataByRating(5, 50, 0): Lấy 50 món ăn/đánh giá 5 sao đầu tiên.
getDataByRating(5, 50, 50): Lấy 50 món ăn/đánh giá 5 sao tiếp theo.


c. Lấy Dữ Liệu Theo Loại

Hàm: getDataByType
Cú pháp:function getDataByType(string memory dataType, uint256 limit, uint256 offset) external view returns (
    uint256[] memory ids,
    string[] memory data,
    string[] memory dataTypes,
    uint256[] memory timestamps,
    uint8[] memory ratings
)


Tham số: Như getLatestData.
Ví dụ:
getDataByType("menu_item", 50, 0): Lấy 50 món ăn trong menu.
getDataByType("menu_item", 50, 50): Lấy 50 món tiếp theo.



d. Lấy Dữ Liệu Theo ID hoặc Hash

Hàm:
getData(uint256 id): Lấy một dữ liệu theo dataId.
getDataByHash(bytes32 dataHash): Lấy một dữ liệu theo hash nội dung.


Ví dụ:
getData(1): Lấy dữ liệu có dataId = 1.
getDataByHash(keccak256("Phở bò")): Tìm món ăn "Phở bò".


e. Lấy Dữ Liệu Hàng Loạt

Hàm: getBatchData
Cú pháp:function getBatchData(uint256 startId, uint256 count) external view returns (
    string[] memory data,
    string[] memory dataTypes,
    uint256[] memory timestamps,
    uint8[] memory ratings
)


Ví dụ:
getBatchData(0, 50): Lấy 50 dữ liệu từ dataId = 0.



f. Lấy Số Lượng Dữ Liệu

Hàm:
getDataTypeCount(string memory dataType): Lấy tổng số dữ liệu theo dataType.
getRatingCount(uint8 rating): Lấy tổng số dữ liệu theo rating.


Ví dụ:
getDataTypeCount("food_review"): Biết số lượng đánh giá để tính số trang.


3. Hỗ Trợ AI Phân Tích

Danh sách dữ liệu: Các hàm getLatestData, getDataByType, getDataByRating trả về danh sách (data, dataTypes, timestamps, ratings) để AI phân tích xu hướng, đề xuất món ăn, hoặc lọc dữ liệu.
Ví dụ:
Lấy 50 đánh giá mới nhất (getLatestData(50, 0, "food_review")) để phân tích món ăn hot.
Lấy 50 món ăn 5 sao (getDataByRating(5, 50, 0)) để đề xuất món chất lượng cao.


4. Tối Ưu Hóa Truy Vấn

Phân trang:
Sử dụng limit và offset để chia nhỏ dữ liệu, tránh vượt giới hạn gas.
Ví dụ: Lấy 1000 đánh giá bằng cách gọi getDataByType("food_review", 50, 0), getDataByType("food_review", 50, 50), v.v.


Chỉ mục off-chain:
Theo dõi sự kiện DataStored để lưu thông tin (dataId, dataType, timestamp, rating) vào cơ sở dữ liệu off-chain (như MongoDB).
AI truy vấn off-chain để chọn dataId, rồi gọi getData hoặc getBatchData để lấy dữ liệu cụ thể.


Ví dụ off-chain:
Lưu sự kiện DataStored vào MongoDB: {dataId: 1, dataType: "food_review", timestamp: 1625097600, rating: 5}.
AI lọc dataId của đánh giá 5 sao, rồi gọi getBatchData.


5. Lưu Ý

Chi phí gas: Lưu timestamp và nhiều ánh xạ (dataTypeToIds, ratingToIds, timeToIds, dataHashToId) tăng chi phí storeData, nhưng đảm bảo tốc độ truy vấn nhanh.
Bảo mật: Chỉ owner có thể gọi storeData.
Mở rộng:
Nếu cần lọc theo khoảng thời gian (ví dụ: 27/6/2025 đến 28/6/2025), liên hệ để thêm hàm getDataByTimeRange.
Có thể mã hóa dataType thành số (ví dụ: 1 cho "food_review") để tiết kiệm bộ nhớ.


