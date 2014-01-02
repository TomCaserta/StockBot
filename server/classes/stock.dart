part of StockBot;

class Stock {
  static Map<int, Stock> _STOCKS = new Map<int, Stock>();
  
  int id = 0;
  bool _init  = false;
  bool _errored = false;
  
  String acronym = "";
  String name = "";
  String info = "";
  String director = "";
  String marketCap = "";
  String demand = "";
  String forecast = "";
  String benefit = "";
  num benefitShares = 0;
  num totalShares = 0;
  num sharesForSale = 0;
  num currentPrice = 0;
  
  DateTime maxDate;
  num max = 0;
  DateTime minDate;
  num min = 0;
  
  DateTime lastUpdate;
  
  Stock._create (this.id) {
    _STOCKS[id] = this;
  }
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<StockData> getTimeRange (DateTime timeFrom, DateTime timeTo) {
    
  }
  
  Future<bool> fetchLatestData (TornGetter tg) {
    Completer c = new Completer();
    
    tg.request("http://www.torn.com/stockexchange.php?step=profile&stock=$id").then((data) { 
      Document parsed = parser.parse(data);
      
      try { 
        this.currentPrice =  num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.STOCK_COST)[0].innerHtml.replaceAll(",", "").replaceAll(r"$", ""), (e) { return 0; });
        this.acronym = childQuerySelector(parsed.body, STOCK_SELECTORS.ACRONYM)[0].innerHtml;    
        this.name = childQuerySelector(parsed.body, STOCK_SELECTORS.NAME)[0].innerHtml;  
        this.info = childQuerySelector(parsed.body, STOCK_SELECTORS.INFO)[0].innerHtml;  
        this.director = childQuerySelector(parsed.body, STOCK_SELECTORS.DIRECTOR)[0].innerHtml;  
        this.marketCap = childQuerySelector(parsed.body, STOCK_SELECTORS.MARKET_CAP)[0].innerHtml;  
        this.demand = childQuerySelector(parsed.body, STOCK_SELECTORS.DEMAND)[0].innerHtml;
        this.totalShares = num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.TOTAL_SHARES)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.sharesForSale = num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.SHARES_FOR_SALE)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.forecast = childQuerySelector(parsed.body, STOCK_SELECTORS.FORECAST)[0].innerHtml;
  
        c.complete(true);
      }
      catch (e) {        
        c.completeError(e);
        this._errored = true;
      }
    }).catchError(c.completeError);
    return c.future;
  }
  
  Future<bool> updateDB (DatabaseHandler dbh) {
    Completer c = new Completer();
    dbh.prepareExecute("INSERT INTO general (stock_id, acro, name, benefit, benefit_shares, min, minDate, max, maxDate, lastUpdate, info, currentCost)"
                        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE acro= VALUES(acro), name = VALUES(name), benefit = VALUES(benefit), benefit_shares = VALUES(benefit_shares), "
                        "min = VALUES(min), minDate = VALUES(minDate), max = VALUES(max), maxDate = VALUES(maxDate), lastUpdate = VALUES(lastUpdate), info = VALUES(info), currentCost = VALUES(currentCost)"
        ,[id, acronym, name, benefit, benefitShares, min, minDate.millisecondsSinceEpoch, max, maxDate.millisecondsSinceEpoch, lastUpdate.millisecondsSinceEpoch, info, currentPrice]).then((Results res) { 
          if (res.affectedRows < 3) {
            c.complete(true);
          }
          else {
            c.completeError("Affected Rows: ${res.affectedRows}");
          }
        }).catchError(c.completeError);
    return c.future;
  }
 
  toJson () {
    return { 'id': id, 'currentPrice':currentPrice, 'acronym': this.acronym, 'name': this.name, 'info': this.info, 'director': this.director, 'marketCap': this.marketCap, 'demand': this.demand, 'totalShares': this.totalShares, 'sharesForSale': this.sharesForSale, 'forecast': this.forecast };
  }
  
  static Future<bool> init (DatabaseHandler dbh) {
    Completer c = new Completer();
    dbh.query("SELECT stock_id, acro, name, benefit, benefit_shares, min, minDate,max, maxDate, lastUpdate, info, currentCost FROM `general`").then((Results res) { 
                res.listen((Row stockRow) { 
                  Stock s = new Stock(stockRow[0]);
                  s.acronym = stockRow[1].toString();
                  s.name = stockRow[2].toString();
                  s.benefit = stockRow[3].toString();
                  s.benefitShares = stockRow[4];
                  s.min = stockRow[5];
                  s.minDate = new DateTime.fromMillisecondsSinceEpoch(stockRow[6] == null ? 0 : stockRow[6]);
                  s.max = stockRow[7];
                  s.maxDate = new DateTime.fromMillisecondsSinceEpoch(stockRow[8] == null ? 0 : stockRow[6]);
                  s.lastUpdate = new DateTime.fromMillisecondsSinceEpoch(stockRow[9] == null ? 0 : stockRow[6]);
                  s.info = stockRow[10].toString();
                  s.currentPrice = stockRow[11];
                }).onDone(() { 
                  c.complete(true);
                });
              });
    return c.future;
  }
}


class StockData {
  int time = 0;
  num CPS = 0.0;
  int sharesAvailable = 0;  
}


class STOCK_SELECTORS { 
  static const String STOCK_COST = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(0) > TD:eq(1)";
  static const String ACRONYM = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR > TD:eq(1)";
  static const String NAME = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > CENTER:eq(0) > FONT:eq(0) > B:eq(0)";
  static const String INFO = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0)";
  static const String DIRECTOR = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
  static const String MARKET_CAP = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
  static const String DEMAND = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(0) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";    
  static const String TOTAL_SHARES = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(4) > TD:eq(1)";
  static const String SHARES_FOR_SALE = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";
  static const String FORECAST = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(4) > TD:eq(1)";
}