import 'package:flutter/material.dart';

class ApiContainer extends StatelessWidget {
  const ApiContainer({
    Key? key,
    required this.result,
  }) : super(key: key);

  final List<int> result;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width * 0.05, // 5% from the left
      top: size.height * 0.33, // 25% from the top
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
        height: size.height * 0.06, // fixed height of 100 pixels

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var item in result)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white54,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 200, 200, 200),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
