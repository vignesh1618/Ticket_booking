import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatScreen extends StatefulWidget {
  @override
  _SeatScreenState createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  String username = "";
  List<String> selectedSeats = [];

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  void fetchUser() async {
    var uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      username = doc['name'];
    });
  }

  // 🔥 POPUP
  void showBookingDialog() async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Booking"),
        content: Text(
            "Selected Seats:\n${selectedSeats.join(", ")}\n\nDo you want to book?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Confirm")),
        ],
      ),
    );

    if (confirm == true) {
      confirmBooking();
    } else {
      setState(() {
        selectedSeats.clear();
      });
    }
  }

  // 🔥 BOOKING
  void confirmBooking() async {
    for (String seatId in selectedSeats) {
      await FirebaseFirestore.instance.collection('seats').doc(seatId).set({
        'booked': true,
        'user': username,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Seats booked successfully")),
    );

    setState(() {
      selectedSeats.clear();
    });
  }

  Widget buildGrid(String prefix) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('seats').snapshots(),
      builder: (context, snapshot) {
        int bookedCount = 0;
        int myBookedCount = 0;

        if (snapshot.hasData) {
          var docs = snapshot.data!.docs;

          bookedCount = docs.length;

          // 🔥 COUNT MY SEATS
          for (var doc in docs) {
            if (doc['user'] == username) {
              myBookedCount++;
            }
          }
        }

        int totalSeats = 60 * 2;
        int availableSeats = totalSeats - bookedCount;

        return Column(
          children: [
            // 🔥 TOP RIGHT INFO
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Available: $availableSeats"),
                    Text("My Seats: $myBookedCount"),
                  ],
                ),
              ),
            ),

            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6, childAspectRatio: 1),
              itemCount: 60,
              itemBuilder: (context, index) {
                String seatId = "$prefix$index";

                bool isBooked = false;

                if (snapshot.hasData) {
                  var docs = snapshot.data!.docs;

                  for (var doc in docs) {
                    if (doc.id == seatId && doc['booked'] == true) {
                      isBooked = true;
                    }
                  }
                }

                bool isSelected = selectedSeats.contains(seatId);

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              selectedSeats.remove(seatId);
                            } else {
                              selectedSeats.add(seatId);
                            }
                          });
                        },
                  child: Container(
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey
                          : isSelected
                              ? Colors.red
                              : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        seatId,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seat Booking"),
        leading: Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: Text(username)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),

                  Text(
                    "Selected Seats: ${selectedSeats.isEmpty ? "None" : selectedSeats.join(", ")}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10),

                  Text("Slot A"),
                  buildGrid("A"),

                  SizedBox(height: 20),

                  Text("Slot B"),
                  buildGrid("B"),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed:
                  selectedSeats.isEmpty ? null : showBookingDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Book My Seat"),
            ),
          )
        ],
      ),
    );
  }
}