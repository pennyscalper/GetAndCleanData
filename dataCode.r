library(ggplot2)

if (Sys.getenv("JAVA_HOME")!="")
  Sys.setenv(JAVA_HOME="")
library(rJava)
Sys.setenv(JAVA_HOME="C:\\Program Files\\Java\\jdk1.6.0_24")
library(xlsx)
library(XML)
library(jsonlite)
library(data.table)


dataLoc = "C:/Documents/modelling/GetAndCleanData/data/";
codeLoc = "C:/Documents/modelling/GetAndCleanData/";
setwd(codeLoc)

###download.file function
fileUrl <- "https://data.baltimorecity.gov/api/views/dz54-2aru/rows.csv?accessType=DOWNLOAD"
setInternet2(TRUE)
download.file(fileUrl, destfile = "./data/cameras.csv");
list.files(dataLoc)
dateDownloaded <- date()
cameraData <- read.table("./data/cameras.csv", sep = ",", header = TRUE)
head(cameraData)


###Reading XLS file
fileUrl <- "https://data.baltimorecity.gov/api/views/dz54-2aru/rows.xlsx?accessType=DOWNLOAD"
setInternet2(TRUE)
download.file(fileUrl, destfile = "./data/cameras.xlsx", method = "curl");
list.files(dataLoc)

cameraData <- read.xlsx("./data/cameras.xlsx",sheetIndex=1,header=TRUE)
colIndex <- 2:3
rowIndex <- 1:4
cameraData <- read.xlsx("./data/cameras.xlsx",sheetIndex=1,colIndex=colIndex,rowIndex=rowIndex, header=TRUE)
head(cameraData)


###reading XML file
fileUrl <- "http://www.w3schools.com/xml/simple.xml"
doc <- xmlTreeParse(fileUrl,useInternal=TRUE)
rootNode <- xmlRoot(doc)
xmlName(rootNode)

rootNode[[1]][[1]]
xmlSApply(rootNode,xmlValue)
xpathSApply(rootNode,"//name",xmlValue); ##get items on the menu by tag name
xpathSApply(rootNode,"//price",xmlValue)

###another example from a football game data
fileUrl <- "http://espn.go.com/nfl/team/_/name/bal/baltimore-ravens"
doc <- htmlTreeParse(fileUrl,useInternal=TRUE)  ##not using xmlTreeParse instead using htmlTreeParse
scores <- xpathSApply(doc,"//li[@class='score']",xmlValue) ##for some reason not extracting all the scores
teams <- xpathSApply(doc,"//li[@class='team-name']",xmlValue)
scores

##Reading JSON data
jsonData <- fromJSON("https://api.github.com/users/jtleek/repos")
names(jsonData)
names(jsonData$owner)
jsonData$owner$login

###writing data frame to JSON
myjson = toJSON(iris, pretty = T);
iris = fromJSON(myjson);

####data.table!! 
####its inherited from data.frame. Much faster than data.frame
DT = data.table(x=rnorm(9),y=rep(c("a","b","c"),each=3),z=rnorm(9))
head(DT,3)
tables() ##list all the data.table objects, its associated size and key(
##calculating inside data.table
DT[, list(mean(x), sum(z))];
DT[,table(y)]; ##can put almost any function inside the data.table and it will compute the function using teh columns from that data table
##adding new column
DT[,w:=z^2]
DT2 <- DT
DT[, y:= 2]
DT[,m:= {tmp <- (x+z); log2(tmp+5)}] ##multiple operations
DT[,a:=x>0] ##plyr like operations
DT[,b:= mean(x+w),by=a]

set.seed(123);
DT <- data.table(x=sample(letters[1:3], 1E5, TRUE))
DT[, .N, by=x] ##very fast; its equivalent is table(DT$x)

##setting key in the data table
DT <- data.table(x=rep(c("a","b","c"),each=100), y=rnorm(300))
setkey(DT, x) ###setting the key as column x
DT['a'] ##very fast                                    

##using keys to facilitate join (merge in data frame)...again its very fast then usual data.frame merge
DT1 <- data.table(x=c('a', 'a', 'b', 'dt1'), y=1:4)
DT2 <- data.table(x=c('a', 'b', 'dt2'), z=5:7)
setkey(DT1, x); setkey(DT2, x)
merge(DT1, DT2)

###Fast reading
big_df <- data.frame(x=rnorm(1E6), y=rnorm(1E6))
file <- tempfile()
write.table(big_df, file=file, row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)
system.time(fread(file))

system.time(read.table(file, header=TRUE, sep="\t"))

###plyr package
