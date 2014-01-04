part of StockBotClient;
 
@NgFilter(name: 'paddednumber')
class PaddedFilter {
  call(number, padding) {
    if (padding is int && number != null) {
      String str = number.toString();
      while (str.length < padding) str = "0$str";
      return str;
    }
  }
}
@NgFilter(name: 'commaseparate')
class CommaSeparateFilter {
  call(num) {
    if (num != null && num is String) {
      List<String> spl = num.split("").reversed.toList();
      List<String> newStr = new List<String>();
      int x = 0;
      spl.forEach((String c) {
        newStr.add(c);
        x++;
        if ((x % 3) == 0 && x != spl.length) {
          newStr.add(",");
        }
      });
      return newStr.reversed.toList().join("");
    }
  }
}

@NgController(
    selector: '[stockOverview]',
    publishAs: 'overview'
)
class StockOverview {
  List<Stock> stocks = new List<Stock>();
  bool get loaded => StockBotModule.loadedStocks;
  bool get loading => StockBotModule.loadingStocks;
  
  bool desc = true;
  String sortBy = "name";
  Timer periodicUpdate;
  DateTime lastRefresh;
  StockOverview () {
     if (!StockBotModule.loggedIn) { 
       window.location.hash = "index";
     }
     else {   
       lastRefresh = new DateTime.now().toUtc();
       if (periodicUpdate == null) {
         updateStocks ();
         periodicUpdate = new Timer.periodic(new Duration(seconds: 10), this.updateStocks);
       }
     }
  }
  
  void updateStocks ([Timer t]) {
    StockBotModule.tryStockUpdate().then((bool complete) {
      stocks = StockBotModule.stocks;
      lastRefresh = new DateTime.now();
    }).catchError((e) { 
      if (t != null) t.cancel();
      print("Stock update error: $e");
      // TODO: DISPLAY ERROR SCREEN;
    });
  }
  
  void resort (String colName) {
    if (colName == sortBy) { desc = !desc; }
    else desc = true;
    this.sortBy = colName;
    List<Stock> tempS = stocks;
    switch (colName) {
      case "acronym":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.acronym.compareTo(elem2.acronym); });
        break;
      case "name":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.name.compareTo(elem2.name); });
        break;
      case "currentPrice":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.currentPrice - elem2.currentPrice; });
        break;
      case "change":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.change - elem2.change; });
        break;
      case "lastUpdate":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.lastUpdate.millisecondsSinceEpoch - elem2.lastUpdate.millisecondsSinceEpoch; });
        break;
      case "sharesAvailable":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.sharesForSale - elem2.sharesForSale; });
        break;
      case "totalShares":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.totalShares - elem2.totalShares; });
        break;
      case "forecast":
        tempS.sort((Stock elem1, Stock elem2) { return demandSorter (elem1.forecast) - demandSorter (elem2.forecast); });
        break;
      case "demand":
        tempS.sort((Stock elem1, Stock elem2) { return demandSorter (elem1.demand) - demandSorter (elem2.demand); });
        break;
        
    }
    if (desc == true) {
      tempS = tempS.reversed.toList();
    }
    stocks = tempS;
  }
}


int demandSorter (String demand) {
  switch (demand) {
    case "N/A":
      return 0;
      break;
    case "High":
      return 3;
      break;
    case "Good": 
      return 3;
      break;
    case "Average":
      return 2;
      break;
    case "Poor":
      return 1;
      break;
    case "Low":
      return 1;
      break;
  }
}