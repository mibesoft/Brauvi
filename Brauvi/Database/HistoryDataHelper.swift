import UIKit
import SQLite
import XCGLogger

typealias History = (
    id:       Int64,
    datetime: Date,
    title:    String,
    url:      String
)

class HistoryDataHelper: DataHelperProtocol {
    static let log = XCGLogger.default
    let log = XCGLogger.default

    static let table    = Table("history")
    static let id       = Expression<Int64>("id")
    static let datetime = Expression<Date>("datetime")
    static let title    = Expression<String>("title")
    static let url      = Expression<String>("url")
    
    typealias T = History
    
    static func createTable() {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            try DB.run( table.create(ifNotExists: true) {t in
                t.column(id, primaryKey: true)
                t.column(datetime)
                t.column(title)
                t.column(url)
            })
        } catch {
            self.log.error(error)
        }
    }
    
    static func insert(item: T) -> Int64 {
        var id: Int64 = 0
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let insert = table.insert(datetime <- item.datetime, title <- item.title, url <- item.url)
            
            id = try DB.run(insert)
        } catch {
            log.error(error)
        }
        return id
    }

    static func delete(item: T) {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let query = table.filter(item.id == rowid)
            
            try DB.run(query.delete())
        } catch {
            log.error(error)
        }
    }
    
    static func deleteAll() -> Int {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            let query = table.delete()
            self.log.info(query.asSQL())
            
            return try DB.run(query)
        } catch {
            log.error(error)
        }
        return 0
    }

    static func update(item: T) {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let query = table.filter(item.id == rowid)
            
            try DB.run(query.update(datetime <- item.datetime, title <- item.title, url <- item.url))
        } catch {
            log.error(error)
        }
    }

    static func find(id: Int64) -> T? {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let query = table.filter(id == rowid)
            
            let items = try DB.prepare(query)
            
            for item in items {
                return History(id: item[HistoryDataHelper.id], datetime: item[datetime], title: item[title], url: item[url])
            }
        } catch {
            log.error(error)
        }
        return nil
    }

    static func findAll() -> [T] {
        var retArray = [T]()
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
         
            let items = try DB.prepare(table)

            for item in items {
                retArray.append(History(id: item[id], datetime: item[datetime], title: item[title], url: item[url]))
            }
        } catch {
            log.error(error)
        }
        return retArray
    }

    static func findAllDatetime() -> [Date] {
        var retArray = [Date]()
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let dateWithoutTime = Expression<Date>("date(datetime)", datetime.bindings)
            let query = table.select(dateWithoutTime).group(dateWithoutTime).order(datetime.desc)
            self.log.info(query.asSQL())
            let items = try DB.prepare(query.asSQL())

            for item in items {
                retArray.append(Date(item[0] as! String))
            }
        } catch {
            log.error(error)
        }
        return retArray
    }

    static func findAll(byDate date: Date) -> [T] {
        var retArray = [T]()
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            
            let dateWithoutTime = Expression<Date>("date(datetime)", datetime.bindings)
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let dateInput = Expression<Date>("'\(df.string(from: date))'", datetime.bindings)
            
            let query = table.filter(dateWithoutTime == dateInput).order(datetime.desc)
            self.log.info(query.asSQL())
            let items = try DB.prepare(query)
            
            for item in items {
                retArray.append(History(id: item[id], datetime: item[datetime], title: item[title], url: item[url]))
            }
        } catch {
            log.error(error)
        }
        return retArray
    }
    
    static func deleteAll(byDate date: Date) {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!

            let dateWithoutTime = Expression<Date>("date(datetime)", datetime.bindings)
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let dateInput = Expression<Date>("'\(df.string(from: date))'", datetime.bindings)
            
            let query = table.filter(dateWithoutTime == dateInput)

            try DB.run(query.delete())
        } catch {
            log.error(error)
        }
    }
    
    static func findLast() -> T? {
        do {
            let DB = SQLiteDataStore.sharedInstance.BBDB!
            let count = try DB.scalar(table.count)
            self.log.info("table.count = \(count)")
            
            if count > 0 {
                let datetimeMaxExpression = Expression<Date>("max(datetime)", datetime.bindings)
            
                let query1 = table.select(datetimeMaxExpression)
                self.log.info(query1.asSQL())
            
                let items1 = try DB.prepare(query1)
            
                for item1 in items1 {
                    let dateTimeMax = item1[datetimeMaxExpression]
                    self.log.info("dateTimeMax = \(dateTimeMax)")
                    
                    let query2 = table.filter(datetime == dateTimeMax)
                    self.log.info(query2.asSQL())
                    let items2 = try DB.prepare(query2)
                    
                    for item2 in items2 {
                        return History(id: item2[HistoryDataHelper.id], datetime: item2[datetime], title: item2[title], url: item2[url])
                    }
                }
            }
        } catch {
            log.error(error)
        }
        return nil
    }
}
