/*import 'dart:html';*/

import 'package:csv_reader/csv_reader.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    String path = null;
    List<FileSystemEntity> files = [];

    Future<int> loadFiles() async {
      List<FileSystemEntity> data = await getLocalFiles();
      List<FileSystemEntity> tmp = [];
      for (int i =0; i<data.length; i++){
        if(data[i] is File){
          tmp.add(data[i]);
        }
      }
      setState(() {
        files = tmp;
      });
      return tmp.length;
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    // For your reference print the AppDoc directory
    return directory.path;
  }
  Future<List<FileSystemEntity>> getLocalFiles() async{
      print("*************************************************");
    final dir = Directory(await _localPath);
    List<FileSystemEntity> files = await dir.listSync().toList();
    return files;
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movesense App'),
      ),
      body: Center(
        child: FutureBuilder(
          initialData: 0 ,
          future: loadFiles(),
          builder: (BuildContext context, AsyncSnapshot snapshot){
            // if(snapshot.data == null){
            //   return Text("loading in progress");
            // }
            if (snapshot.data == 0){
              return Text("No Data");
            }

            return ListView.builder(
                itemCount: files.length,
                itemBuilder: (BuildContext context, int i){
                  String name = files[i].path.split("/").last;
              return ListTile(
                onTap: () async {

                  Navigator.push(context,
                      MaterialPageRoute<void>(
                          builder:(BuildContext context) {
                            return DataTablePage(path:files[i].path);
                          }));
                },
                title: Text(name, overflow: TextOverflow.ellipsis,),
              );
            });

          },
        )
      ),
      floatingActionButton: IconButton(
        color: Colors.blue,
        iconSize: 50,
        icon: Icon(Icons.add_circle),
        onPressed: () async {
          FilePickerResult result = await FilePicker.platform.pickFiles();
           if(result != null) {
             String filePath = result.files.single.path;
             String fileName = result.files.single.name;
             File file = File(filePath);
             file.copySync(await _localPath + "/" + fileName);
             await loadFiles();
           }
        },
      ),
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/lake4.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
              child: Container(
                child:
                RaisedButton(
                  onPressed: (){
                    Navigator.push(context,
                        MaterialPageRoute<void>(
                            builder:(BuildContext context) {
                              return HomePage();
                            }));
                  },
                  color: Colors.blueGrey,
                  child:
                  Text('File'),textColor: Color(0X99FFFFFF),),
              )
          )
        ],
      )
    );

  }
}
///////////////////////////////////////////////////////////////////////////////////////////////////
class DataTablePage extends StatelessWidget {

  String path;
  DataTablePage({this.path});

  Future<List<List<String>>> loadCSV (String path)  async {
    String csvRawData = await rootBundle.loadString(path);
    List<String> lineList = csvRawData.split("\n");
    List<List<String>> formatedData = List<List<String>>(lineList.length - 1);
    String delimiter = "";
    if (lineList[0].contains(';')) {
      delimiter = ';';
    } else {
      delimiter = ',';
    }
    for(int i = 0; i < lineList.length; i++) {
      String line = lineList[i];
      if(line.isNotEmpty) {
        formatedData[i] = line.split(delimiter);
      }
    }
    return formatedData;

  }
/////////TRANSFORMATION CSV////////////
  Future<List<List<String>>> loadCSVFromFile (String path)  async {
    File file = File(path);
    String csvRawData = await file.readAsString();
    List<String> lineList = csvRawData.split("\n");
    List<List<String>> formatedData = List<List<String>>(lineList.length - 1);
    String delimiter = "";
    if (lineList[0].contains(';')) {
      delimiter = ';';
    } else {
      delimiter = ',';
    }
    for(int i = 0; i < lineList.length; i++) {
      String line = lineList[i];
      if(line.isNotEmpty) {
        formatedData[i] = line.split(delimiter);
      }
    }
    return formatedData;
  }

  ////////////////////////SECOND PAGE/////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movesense App'),
      ),
      body: FutureBuilder(
          future: loadCSVFromFile(path),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // this condition is important
            if (path == null) {
             return Center(
              child: Text("no path"),);
            }
            if (snapshot.data == null) {
              return Center(
                child: Text('loading data'),
              );
            } else {
              List<List<String>> data = snapshot.data;
              List<String> header = data[0];

              List<List<String>> body = data.getRange(1, 10).toList();

              List<DataColumn> headerDataColumns = header.map((e) {
                return DataColumn(label: Text(e));
              }).toList();

              List<DataRow> bodyDataRow = body.map((line){
                List<DataCell> cells = line.map( (cell) {
                  return DataCell(Text(cell));
                }).toList();
                return DataRow(cells: cells);
              }).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: headerDataColumns,
                    rows: bodyDataRow,
                  ),
                ),
              );
            }
          }),
    );
  }
}

