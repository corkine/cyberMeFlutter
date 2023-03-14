import 'package:flutter_test/flutter_test.dart';
import 'package:cyberme_flutter/pocket/models/plant.dart';

void main() {
  group("Plant Bean Test", () {
    test("Create Bean with properties OK", () {
      var bean = Plant();
      expect(bean.data, [], reason: "默认创建即为空数据");
      bean.data = List.generate(7, (index) => 0);
      expect(bean.todayWater, false);
      expect(bean.weekWater, List.generate(7, (index) => false));
      DateTime now = DateTime.now();
      var res = [];
      switch (now.weekday.toInt()) {
        case 1:
          res = ['', '', '', '', '', '', ''];
          break;
        case 2:
          res = ['🍂', '', '', '', '', '', ''];
          break;
        case 3:
          res = ['🍂', '🍂', '', '', '', '', ''];
          break;
        case 4:
          res = ['🍂', '🍂', '🍂', '', '', '', ''];
          break;
        case 5:
          res = ['🍂', '🍂', '🍂', '🍂', '', '', ''];
          break;
        case 6:
          res = ['🍂', '🍂', '🍂', '🍂', '🍂', '', ''];
          break;
        case 7:
          res = ['🍂', '🍂', '🍂', '🍂', '🍂', '🍂', ''];
          break;
        default:
          res = [];
      }
      expect(bean.weekWaterStr, res);
    });
  });
}
