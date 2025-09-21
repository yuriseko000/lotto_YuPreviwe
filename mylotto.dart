// นำเข้า library ที่จำเป็น
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// นำเข้าไฟล์อื่นๆในโปรเจกต์
import 'home.dart';
import 'setting.dart';
import 'model/login_model.dart';
import 'config.dart';

// Widget หลักของหน้านี้
class MyLottoPage extends StatefulWidget {
  final Customer customer; // รับข้อมูลลูกค้าที่ login เข้ามา
  const MyLottoPage({super.key, required this.customer});

  @override
  State<MyLottoPage> createState() => _MyLottoPageState(); // คือข้อมูลที่ใช้ควบคุมและอัปเดตหน้าจอของ Widget ในขณะที่แอปทำงาน
}

class _MyLottoPageState extends State<MyLottoPage> {
  List<dynamic> myLotto = []; // เก็บรายการล็อตเตอรี่ของผู้ใช้
  bool isLoading = true; // กำลังโหลดข้อมูล (เช่น กำลังดึงข้อมูลจาก API)

  Map<int, List<dynamic>> prizeByRound =
      {}; // เก็บผลรางวัลแยกตามรอบ (key = round, value = รายการรางวัล)
  final TextEditingController _searchController =
      TextEditingController(); // ตัวควบคุมข้อความค้นหา
  String _searchText = ''; // ข้อความค้นหา

  @override
  void initState() {
    super.initState();
    fetchMyLotto(); // เรียกตอนแรกเพื่อดึงข้อมูลล็อตเตอรี่ของลูกค้า
  }

  // ฟังก์ชันดึงข้อมูลล็อตเตอรี่ที่ลูกค้าซื้อ
  Future<void> fetchMyLotto() async {
    final url = Uri.parse(
      // ใช้ AppConfig.apiEndpoint เพื่อสร้าง URL
      "${AppConfig.apiEndpoint}/my-lotto/${widget.customer.cusId}", // ใช้ cusId ของลูกค้าเพื่อดึงข้อมูล
    );
    try {
      final response = await http.get(url); // ส่งคำขอ GET ไปยัง API
      if (response.statusCode == 200) {
        // ถ้าสถานะตอบกลับเป็น 200 (สำเร็จ)
        final data = json.decode(
          response.body,
        ); // แปลงข้อมูล JSON ที่ได้รับเป็น Map
        setState(() {
          // อัพเดทสถานะของ Widget
          myLotto = data["myLotto"]; // เก็บรายการล็อตเตอรี่
          isLoading = false; // โหลดข้อมูลเสร็จแล้ว สามารถแสดงผลข้อมูลได้
        });

        final rounds = myLotto
            .map((e) => e["round"])
            .toSet(); // ดึงรอบที่ลูกค้ามีล็อตเตอรี่
        for (final r in rounds) {
          // ดึงผลรางวัลสำหรับแต่ละรอบ
          fetchPrize(r);
        }
      } else {
        throw Exception("โหลดข้อมูลไม่สำเร็จ");
      }
    } catch (e) {
      setState(() {
        isLoading = false; //โหลดข้อมูลเสร็จแล้ว สามารถแสดงผลข้อมูลได้
      });
      print("Error: $e");
    }
  }

  // ฟังก์ชันดึงผลรางวัลสำหรับรอบที่ระบุ
  Future<void> fetchPrize(int round) async {
    if (prizeByRound.containsKey(round))
      return; // ถ้ามีข้อมูลรางวัลสำหรับรอบนี้แล้ว ให้ข้ามไป

    final url = Uri.parse(
      "${AppConfig.apiEndpoint}/prize/$round",
    ); // สร้าง URL สำหรับดึงผลรางวัล
    try {
      final response = await http.get(url); // ส่งคำขอ GET ไปยัง API
      if (response.statusCode == 200) {
        // ถ้าสถานะตอบกลับเป็น 200 (สำเร็จ)
        final data = json.decode(
          response.body,
        ); // แปลงข้อมูล JSON ที่ได้รับเป็น Map
        setState(() {
          prizeByRound[round] =
              data["prizes"]; // เก็บผลรางวัลในแผนที่ prizeByRound
        });
      }
    } catch (e) {
      print("Error fetching prize for round $round: $e");
    }
  }

  List<Map<String, dynamic>> checkPrizes(int round, String number) {
    // ตรวจสอบว่าหมายเลขล็อตเตอรี่ถูกรางวัลหรือไม่
    final prizes = prizeByRound[round]; // ดึงผลรางวัลสำหรับรอบที่ระบุ
    if (prizes == null)
      return []; // ถ้าไม่มีรางวัลสำหรับรอบนี้ ให้คืนค่าเป็นลิสต์ว่าง

    List<Map<String, dynamic>> won = []; // เก็บรางวัลที่ถูกรางวัล
    for (final prize in prizes) {
      // ตรวจสอบแต่ละรางวัล
      if (prize["prize_type"] == "เลขท้าย 3 ตัว") {
        // ตรวจสอบรางวัลเลขท้าย 3 ตัว
        if (number.substring(number.length - 3) ==
            prize["number"]) //substring ดึง 3 ตัวท้าย
          won.add(prize); // ถ้าตรงกัน ให้เพิ่มรางวัลนี้ลงในลิสต์ won
      } else if (prize["prize_type"] == "เลขท้าย 2 ตัว") {
        // ตรวจสอบรางวัลเลขท้าย 2 ตัว
        if (number.substring(number.length - 2) ==
            prize["number"]) //substring ดึง 2 ตัวท้าย
          won.add(prize); // ถ้าตรงกัน ให้เพิ่มรางวัลนี้ลงในลิสต์ won
      } else {
        if (number == prize["number"]) won.add(prize); // ตรวจสอบหมายเลขทั้งหมด
      }
    }
    return won; // คืนค่ารายการรางวัลที่ถูกรางวัล
  }

  int getRewardAmount(Map<String, dynamic> prize) {
    // ดึงจำนวนเงินรางวัลจากรางวัลที่ถูกรางวัล
    return prize["reward_amount"] ?? 0; // ถ้าไม่มีข้อมูล ให้คืนค่าเป็น 0
  }

  // ฟังก์ชันสำหรับขึ้นเงินรางวัล
  Future<void> redeemPrize(Map<String, dynamic> lotto) async {
    final purchaseId = lotto["purchase_id"]; // ดึง purchase_id ของล็อตเตอรี่
    final round = lotto["round"]; // ดึงรอบและหมายเลขล็อตเตอรี่
    final number = lotto["number"]; // ดึงหมายเลขล็อตเตอรี่

    final url = Uri.parse(
      "${AppConfig.apiEndpoint}/redeem/$purchaseId",
    ); // สร้าง URL สำหรับขึ้นเงินรางวัล
    try {
      final response = await http.post(url); // ส่งคำขอ POST ไปยัง API
      if (response.statusCode == 200) {
        // ถ้าสถานะตอบกลับเป็น 200 (สำเร็จ)
        final data = json.decode(
          response.body,
        ); // แปลงข้อมูล JSON ที่ได้รับเป็น Map

        final prizes = checkPrizes(round, number); // ตรวจสอบรางวัลที่ถูกรางวัล
        final totalReward = prizes.fold(
          //คำนวณยอดเงินรางวัลรวม
          0,
          (sum, p) =>
              sum +
              getRewardAmount(
                p,
              ), // ใช้ฟังก์ชัน getRewardAmount เพื่อดึงจำนวนเงินรางวัล
        );

        setState(() {
          // อัพเดทยอดเงินใน wallet ของลูกค้าและสถานะการขึ้นเงินรางวัล //setstate เพื่อรีเฟรชหน้าจอ ให้เป็นค่าใหม่
          widget.customer.walletBalance +=
              totalReward; // เพิ่มยอดเงินรางวัลเข้า wallet
          lotto["is_redeemed"] =
              1; // อัพเดทสถานะการขึ้นเงินรางวัลในรายการล็อตเตอรี่
        });

        ScaffoldMessenger.of(context).showSnackBar(
          // แสดงข้อความแจ้งเตือน
          SnackBar(content: Text(data["message"] ?? "ขึ้นเงินรางวัลแล้ว")),
        );
      } else {
        final err = json.decode(
          response.body,
        ); // แปลงข้อมูล JSON ที่ได้รับเป็น Map
        ScaffoldMessenger.of(context).showSnackBar(
          // แสดงข้อความแจ้งเตือน
          SnackBar(content: Text(err["message"] ?? "ไม่สามารถขึ้นเงินได้")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // แสดงข้อความแจ้งเตือน
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  List<dynamic> get filteredLotto {
    // กรองรายการล็อตเตอรี่ตามข้อความค้นหา
    if (_searchText.isEmpty) return myLotto;
    return myLotto.where((lotto) {
      final number =
          lotto["number"]?.toString() ??
          ''; //เลือกเฉพาะล็อตเตอรี่ที่ number มีข้อความนั้นอยู่
      return number.contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = widget.customer.walletBalance;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Lotto - ${widget.customer.fullname}'),
        backgroundColor: const Color(0xFF001E46),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาล็อตเตอรี่',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchText = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchText = _searchController.text.trim();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001E46),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'ค้นหา',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 0, bottom: 8.0),
            child: Row(
              children: [
                const Text(
                  "My Wallet: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "฿${walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLotto.isEmpty
                ? const Center(child: Text("ยังไม่มีการซื้อ"))
                : ListView.builder(
                    itemCount: filteredLotto.length,
                    itemBuilder: (context, index) {
                      final lotto = filteredLotto[index];
                      final number = lotto["number"].toString();
                      final round = lotto["round"];
                      final purchaseDate = lotto["purchase_date"];
                      final claimed = lotto["is_redeemed"] == 1;

                      final prizes = checkPrizes(round, number);
                      Color cardColor = Colors.white;
                      String prizeText = "ยังไม่สุ่มรางวัล";
                      Color prizeTextColor = Colors.orange;
                      String prizeTypeText = "";

                      if (prizeByRound.containsKey(round)) {
                        if (prizes.isEmpty) {
                          prizeText = "ไม่ถูกรางวัล";
                          prizeTextColor = Colors.red;
                        } else {
                          cardColor = Colors.green[50]!;
                          if (claimed) {
                            prizeText = "ขึ้นเงินรางวัลแล้ว";
                            prizeTextColor = Colors.blue;
                          } else {
                            prizeText =
                                "ถูกรางวัล: ${prizes.map((p) => p["prize_type"]).join(", ")}";
                            prizeTextColor = Colors.green;
                          }
                          final totalReward = prizes.fold(
                            0,
                            (sum, p) => sum + getRewardAmount(p),
                          );
                          prizeTypeText = "รวมเงินรางวัล: $totalReward บาท";
                        }
                      }

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "ฉลากกินแบ่ง: $number",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Text(
                                    "งวดที่: $round",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "วันที่ซื้อ: $purchaseDate",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prizeText,
                                          style: TextStyle(
                                            color: prizeTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (prizeTypeText.isNotEmpty)
                                          Text(
                                            prizeTypeText,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  (!claimed && prizes.isNotEmpty)
                                      ? ElevatedButton(
                                          onPressed: () => redeemPrize(lotto),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text(
                                            'ขึ้นเงินรางวัล',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFFF1F7F8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(customer: widget.customer),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.home, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Home',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.confirmation_number, color: Colors.blue),
                SizedBox(height: 4),
                Text(
                  'MyLotto',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingPage(customer: widget.customer),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Setting',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
