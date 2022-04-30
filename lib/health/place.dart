import 'package:flutter/material.dart';
import '../learn/data.dart';
import '../util.dart';

class HealthCheck extends StatefulWidget {
  final Info info;

  const HealthCheck({Key? key, required this.info}) : super(key: key);

  @override
  State<HealthCheck> createState() => _HealthCheckState();
}

class _HealthCheckState extends State<HealthCheck> {
  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Info.blue,
        elevation: 0,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                "社区通行登记",
                style: Info.titleStyle,
              ),
            ),
            Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    "images/home.png",
                    width: 29,
                    height: 29,
                  ),
                )),
            Positioned(
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: const Color.fromRGBO(78, 118, 207, 1)),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 3, bottom: 3),
                    child: Row(
                      children: [
                        Image.asset(
                          "images/more.png",
                          width: 23,
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Container(
                            width: 1,
                            height: 16,
                            color: const Color.fromRGBO(73, 113, 200, 1),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            //exit(0);
                          },
                          child: const Icon(
                            Icons.adjust,
                            color: Colors.white,
                            size: 19,
                          ),
                        )
                      ],
                    ),
                  ),
                ))
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Stack(
          children: [
            Positioned(
                //蓝色背景
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 113,
                  color: Info.blue,
                )),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildUserCard(),
                  const SizedBox(
                    height: 15,
                  ),
                  buildCheckPlace(),
                  const SizedBox(
                    height: 15,
                  ),
                  buildInputStatus(),
                  ...(isClicked
                      ? ([
                          const SizedBox(
                            height: 0,
                          )
                        ])
                      : [
                          buildCheckInfo(),
                          buildButton(),
                          const SizedBox(
                            height: 15,
                          )
                        ]),
                  const SizedBox(
                    height: 15,
                  ),
                  buildLastButton()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Container buildLastButton() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      width: double.infinity,
      decoration: Info.box,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Image.asset(
                    "images/back.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "外地来（返）汉人员信息申报",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  Image.asset(
                    "images/policy.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "各地防疫政策",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  Image.asset(
                    "images/area.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "全国中高风险地区",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Image.asset(
                    "images/trival.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "行程查询",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  Image.asset(
                    "images/hospital.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "发热门诊导航",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  Image.asset(
                    "images/help2.png",
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text(
                      "客服",
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Container buildButton() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
                const EdgeInsets.only(left: 0, right: 0)),
          ),
          onPressed: () {
            setState(() {
              isClicked = true;
            });
          },
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
                color: Info.blue, borderRadius: BorderRadius.circular(3)),
            alignment: Alignment.center,
            child: const Text(
              "提交",
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          )),
    );
  }

  Padding buildCheckInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 20,
            padding:
                const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
            child: Checkbox(
              value: true,
              onChanged: (e) {},
              activeColor: Info.blue,
            ),
          ),
          Flexible(
              child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "我已阅知本申报所列事项，并保证以上申报内容正确属实",
              style: TextStyle(color: Info.grey),
              softWrap: true,
            ),
          ))
        ],
      ),
    );
  }

  Container buildInputStatus() {
    var out = Row(
      children: [
        Image.asset(
          "images/check2.png",
          width: 24,
          height: 24,
        ),
        const SizedBox(
          width: 5,
        ),
        const Text(
          "外出",
          style: TextStyle(fontSize: 15),
        )
      ],
    );
    var in_to = Row(
      children: [
        Image.asset(
          "images/check.png",
          width: 24,
          height: 24,
        ),
        const SizedBox(
          width: 5,
        ),
        const Text(
          "入内",
          style: TextStyle(fontSize: 15),
        )
      ],
    );
    var pass = Row(
      children: [
        Image.asset(
          "images/check2.png",
          width: 24,
          height: 24,
        ),
        const SizedBox(
          width: 5,
        ),
        const Text(
          "途径",
          style: TextStyle(fontSize: 15),
        )
      ],
    );
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      width: double.infinity,
      decoration: Info.box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "出行状态",
            style: TextStyle(color: Info.grey, fontSize: 14),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: isClicked
                  ? ([
                      Opacity(
                        opacity: 0.3,
                        child: in_to,
                      )
                    ])
                  : ([out, in_to, pass]),
            ),
          )
        ],
      ),
    );
  }

  Container buildCheckPlace() {
    return Container(
      width: double.infinity,
      decoration: Info.box,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "核验地点",
            style: TextStyle(color: Info.grey, fontSize: 14),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              widget.info.checkPlace,
              style: const TextStyle(color: Colors.black, fontSize: 17),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 6),
            child: Divider(
              thickness: 1.5,
              color: Color.fromRGBO(189, 189, 189, 0.2),
            ),
          ),
          Text(
            "扫码时间",
            style: TextStyle(color: Info.grey, fontSize: 14),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              Util.clock(justBeforeSeconds: true) +
                  Util.clock(justSeconds: true),
              style: const TextStyle(color: Colors.black, fontSize: 17),
            ),
          )
        ],
      ),
    );
  }

  Container buildUserCard() {
    return Container(
      width: double.infinity,
      decoration: Info.box,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //文字
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 23, right: 10, top: 15, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "姓名",
                          style: TextStyle(color: Info.grey, fontSize: 14),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          Info.middleStarName(widget.info),
                          style: const TextStyle(
                              color: Color.fromRGBO(46, 46, 50, 1),
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 15, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "状态",
                          style: TextStyle(color: Info.grey, fontSize: 14),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          "正常通行",
                          style: TextStyle(
                              color: Color.fromRGBO(122, 176, 110, 1),
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 10, top: 15, bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: widget.info.testInfo.contains("48")
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                  Color.fromRGBO(116, 186, 130, 1),
                                  Color.fromRGBO(158, 224, 138, 0.95)
                                ])
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                  Color.fromRGBO(101, 130, 254, 1),
                                  Color.fromRGBO(128, 178, 255, 1)
                                ]),
                      borderRadius: BorderRadius.circular(5)),
                  padding: const EdgeInsets.only(
                      left: 12, right: 10, top: 3, bottom: 3),
                  child: Text(
                    "核酸检测：${widget.info.testInfo}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
              //健康码
              Util.pickTime() == null
                  ? const SizedBox(height: 4, width: 0,)
                  : Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 10, top: 1, bottom: 17),
                      child: Text(
                        "核酸 已采样 ${Util.pickTime()}",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 135, 66, 1)),
                      ))
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 13),
            child: Image.asset(
              "images/code2.png",
              width: 97,
              height: 97,
            ),
          )
        ],
      ),
    );
  }
}
