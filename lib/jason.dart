import 'dart:convert';

void test() {
Map<String , dynamic> map =
	{
		"name": "박해솔",
		"age": 29
	,
		"name": "김혜정",
		"age": 31
	};

  String jasonData = jsonEncode(map);


}