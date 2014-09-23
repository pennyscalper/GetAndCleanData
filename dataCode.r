library(ggplot2)

if (Sys.getenv("JAVA_HOME")!="")
  Sys.setenv(JAVA_HOME="")
library(rJava)
Sys.setenv(JAVA_HOME="C:\\Program Files\\Java\\jdk1.6.0_24")
library(xlsx)
library(XML)
library(jsonlite)
library(data.table)
onMac = F;

if(Sys.getenv("HOME") == "/Users/praveen") {
  dataLoc = "/Users/praveen/Desktop/DataScience/GetAndCleanData/data";
  codeLoc = "/Users/praveen/Desktop/DataScience/GetAndCleanData";  
  onMac = T;
} else {
dataLoc = "C:/Documents/modelling/GetAndCleanData/data/";
codeLoc = "C:/Documents/modelling/GetAndCleanData/";
}
setwd(codeLoc)

###download.file function
fileUrl <- "https://data.baltimorecity.gov/api/views/dz54-2aru/rows.csv?accessType=DOWNLOAD"
if(!onMac) {
setInternet2(TRUE)
download.file(fileUrl, destfile = "./data/cameras.csv");
} else {
  download.file(fileUrl, destfile = "./data/cameras.csv", method = "curl");
}
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

##############################################################################################################################data.table!! 
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
DT3 = data.table(x = sample(c('a', 'b', 'a', 'b', 'dt2'), size = 10, replace = TRUE), u = rnorm(10))
setkey(DT1, x); setkey(DT2, x); setkey(DT3, x)
DT1["a"]; DT1["a",]; ##putputs column x == "a" rows
##for multiple cols keys DT1[J("a", "b", "c")]  ==> if key has three cols then this will output rows where col1 == "a" & col2 == "b" & col3 == "c"
merge(DT1, DT2)

###J(join), CJ and SJ
DT = CJ(x = letters[1:5], y = runif(3), z = c("aa", "bb")); ##A data.table is formed from the cross product of the vectors. For example, 10 ids, and 100 dates, CJ returns a 1000 row table containing all the dates for all the ids.
DT[, x1:= sample(LETTERS, nrow(DT), replace = T)];
DT[, .N, by=list(x, x1)]; DT[, list(mean(y), median(y)), by=list(x, x1)]
setkey(DT, x, x1);
DT[J("d", "T")]; DT[.("b", "H")]; DT[list("b", "H")]; ##all outputs same and is very fast because keys are sorted and this runs the binary search 
DT[x == "d" &  x1 == "T"]; ##using data.table badly and is as slow as data frame
##J("d", "T") is a data.table when written inside DT[]

###showing the speed differences between data.frame and data.table
grpsize = ceiling(1e7/26^2); tt=system.time( DF <- data.frame(x=rep(LETTERS,each=26*grpsize),y=rep(letters,each=grpsize),v=runif(grpsize*26^2),stringsAsFactors=FALSE))
system.time(ans1 <- DF[DF$x=="R" & DF$y=="h",])
DT = as.data.table(DF); system.time(setkey(DT,x,y)); system.time(ans2 <- DT[J("R","h")])
identical( DT[J("R","h"),], DT[data.table("R","h"),]) ##returns true 
DT[CJ(c("A","R"),c("h", "a")),]; #CJ creates a DF with crossing c("A","R") and c("h", "a"), hence 4 rows. joins that with DT to subset DT. this is similar to merge but much faster
DT[CJ(c("A","R"),c("h", "a")), list(count = .N, avg = mean(v), sd = sd(v)), by="x,y"] #does what table function does
#########################3. Fast time series join
#This is also known as last observation carried forward (LOCF) or a rolling join.
#Recall that x[i] is a join between data.table x and data.table i. If i has 2 columns, the
#First column is matched to theFirst column of the key of x, and the 2nd column to the 2nd. An
#equi-join is performed, meaning that the values must be equal.
#The syntax for fast rolling join is
#x[i,roll=TRUE]
#As before the First column of i is matched to x where the values are equal. The last column
#of i though, the 2nd one in this example, is treated specially. If no match is found, then the row
#before is returned, provided theFirst column still matches.
#For examples type 
DT = data.table(x=rep(c("a","b","c"),each=3), y=c(1,3,6), v=1:9); setkey(DT,x)
example(data.table)
DT[,.SD[which.min(v)],by=x][] # nested query by group; .SD is subset data broken by "by". then on individual SD applying which.min(v)
DT[,.SD[2],by=x] # 2nd row of each group
DT[,tail(.SD,2),by=x] # last 2 rows of each group
DT[,lapply(.SD,sum),by=x] # apply through columns by group
DT[,lapply(tail(.SD,2), sum),by=x] # last 2 rows of each group and on top of that do sum of each column in every subset by applying lapply
setkey(DT,x,y)
DT[,list(MySum=sum(v), MyMin=min(v), MyMax=max(v)), by=list(x,y%%2)] # by 2 expressions
DT[,sum(v),x][V1<20]
print(DT[,z:=42L]) # add new column by reference
print(DT[,z:=NULL]) # remove column by reference
print(DT["a",v:=42L]) # subassign to existing v column by reference
DT[!J("a")] # not join
DT[!"a"] # same
DT[!2:4] # all rows other than 2:4
DT[x!="b" | y!=3] # multiple vector scanning approach, slow
DT[!J("b",3)] # same result but much faster

DT = data.table(a=LETTERS[c(1,1:3)],b=4:7,key="a")
DT[2,d:=10L] # subassign by reference to column d; where key == 2 it puts d = 10 and rest NA
duplicated(DT); #runs it on keys by default if variable by is not provided
unique(DT); #runs it on keys by default if variable by is not provided 

###some transformation done by transform or within can be done by := in data table
DT <- data.table(a=rep(1:3, each=2), b=1:6)
DT2 <- transform(DT, c = a^2)
DT[, c:=a^2]
identical(DT,DT2)
DT2 <- within(DT, {b <- rev(b) 
c <- a*2 
rm(a)})
DT[,':='(b = rev(b), c = a*2, a = NULL)]
identical(DT,DT2)

DT$d = ave(DT$b, DT$c, FUN=max) # copies entire DT, even if it is 10GB in RAM
DT = DT[, transform(.SD, d=max(b)), by="c"] # same, but even worse as .SD is copied for each group
DT[, d:=max(b), by="c"] # same result, but much faster, shorter and scales
# Multiple update by group. Convenient, fast, scales and easy to read.
DT[, `:=`(minb = min(b),
meanb = mean(b),
bplusd = sum(b+d)), by=c%/%5]

###Fast reading
big_df <- data.frame(x=rnorm(1E6), y=rnorm(1E6))
file <- tempfile()
write.table(big_df, file=file, row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)
system.time(fread(file))

system.time(read.table(file, header=TRUE, sep="\t"))
##############################################################################################################################Finished data.table!! 

###HDF5 package
source("http://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
###creating an hdf5 file names "example.h5"
created = h5createFile("example.h5")
created

##creating hierarchical groups 
created = h5createGroup("example.h5","foo")
created = h5createGroup("example.h5","baa")
created = h5createGroup("example.h5","foo/foobaa")
h5ls("example.h5")

###filling data for the groups and also creating new groups with data
A = matrix(1:10,nr=5,nc=2)
h5write(A, "example.h5","foo/A")
B = array(seq(0.1,2.0,by=0.1),dim=c(5,2,2))
attr(B, "scale") <- "liter"
h5write(B, "example.h5","foo/foobaa/B")
h5ls("example.h5")
df = data.frame(1L:5L,seq(0,1,length.out=5),
                c("ab","cde","fghi","a","s"), stringsAsFactors=FALSE)
h5write(df, "example.h5","df")
h5ls("example.h5")

###reading data from hdf5 file
readA = h5read("example.h5","foo/A")
readB = h5read("example.h5","foo/foobaa/B")
readdf= h5read("example.h5","df")
readA

###writing and reading chunks
h5write(c(12,13,14),"example.h5","foo/A",index=list(1:3,1))
h5read("example.h5","foo/A")


###########Reading data from web....webscrapping
con = url("http://scholar.google.com/citations?user=HI-I6C0AAAAJ&hl=en")
htmlCode = readLines(con)
close(con)
htmlCode
url <- "http://scholar.google.com/citations?user=HI-I6C0AAAAJ&hl=en"
html <- htmlTreeParse(url, useInternalNodes=T) ##get the internal nodes 
xpathSApply(html, "//title", xmlValue) ##no of times the papers are cited by

###reading data from online APIs...examlple twitter
library(httr)
##read https://dev.twitter.com/docs/api/1.1/overview and then code

###plyr package...basic idea is split-apply-combine
library(plyr)
set.seed(13435)
X <- data.frame("var1"=sample(1:5),"var2"=sample(6:10),"var3"=sample(11:15))
X <- X[sample(1:5),]; X$var2[c(1,3)] = NA
arrange(X, var1); arrange(X, desc(var1)); ##ordering X by column var1

if(!file.exists("./data")){dir.create("./data")}
fileUrl <- "https://data.baltimorecity.gov/api/views/k5ry-ef3g/rows.csv?accessType=DOWNLOAD"
download.file(fileUrl,destfile="./data/restaurants.csv",method="curl")
restData <- read.csv("./data/restaurants.csv")
summary(restData); str(restData); 
table(restData$zipCode,useNA="ifany"); ##use useNA display # of nas
table(restData$zipCode %in% c("21212","21213"))

data(UCBAdmissions)
DF = as.data.frame(UCBAdmissions)
summary(DF)
##cross table...similar to contingency table if doing counts
xt <- xtabs(Freq ~ Gender + Admit,data=DF); ##cross tabs
xt
##cross tab on more than two variable
warpbreaks$replicate <- rep(1:9, len = 54)
xt = xtabs(breaks ~.,data=warpbreaks)
xt
##converting above cross tab into flat table
ftable(xt)


###size of the objects
fakeData = rnorm(1e5)
object.size(fakeData)
print(object.size(fakeData),units="Mb") ##in Mb

if(!file.exists("./data")){dir.create("./data")}
fileUrl <- "https://data.baltimorecity.gov/api/views/k5ry-ef3g/rows.csv?accessType=DOWNLOAD"
download.file(fileUrl,destfile="./data/restaurants.csv",method="curl")
restData <- read.csv("./data/restaurants.csv")

##easier cutting of the data
library(Hmisc)
restData$zipGroups = cut2(restData$zipCode,g=4)
table(restData$zipGroups)
###doing the same using mutate function from plyr package
restData2 = mutate(restData,zipGroups=cut2(zipCode,g=4))
table(restData2$zipGroups)
###melting the data frame to reshape
library(reshape2)
head(mtcars)
mtcars$carname <- rownames(mtcars)
carMelt <- melt(mtcars,id=c("carname","gear","cyl"),measure.vars=c("mpg","hp"))
##melt creates 2 columns and one "variable" column with value "mpg" or "hp" and one "value" column
head(carMelt,n=3)
###decasting the melted data frame
cylData <- dcast(carMelt, cyl ~ variable, fun.aggregate = mean) ##just like aggregate fuction
cylData
###using split apply and combine
head(InsectSprays)
spIns =  split(InsectSprays$count,InsectSprays$spray) ###split
spIns
##lapply...apply a function to individual list
sprCount = lapply(spIns,sum) ###apply
sprCount
unlist(sprCount); ##combine...to get it in vector form
sapply(spIns,sum); ##apply and combine in in one step

###another way using ddply from plyr package which splits apply and combine in one commanc
ddply(InsectSprays,.(spray),summarize,sum=sum(count))

###merging more than one data frame using join_all in package plyr
df1 = data.frame(id1=sample(1:10),x=rnorm(10))
df2 = data.frame(id1=sample(1:10),y=rnorm(10))
df3 = data.frame(id1=sample(1:10),z=rnorm(10))
dfList = list(df1,df2,df3)
arrange(join_all(dfList), desc(id1)); arrange(join_all(dfList), id1); #second one in ascending order of id1

####Editing text variables...regular expressions etc
tolower(LETTERS[1:10]); #toupper

if(!file.exists("./data")){dir.create("./data")}
fileUrl <- "https://data.baltimorecity.gov/api/views/dz54-2aru/rows.csv?accessType=DOWNLOAD"
download.file(fileUrl,destfile="./data/cameras.csv",method="curl")
cameraData <- read.csv("./data/cameras.csv")
names(cameraData)

###truncating the names after "."
splitNames = strsplit(names(cameraData),"\\.")
firstElement <- function(x){x[1]}
sapply(splitNames,firstElement)

fileUrl1 <- "https://dl.dropboxusercontent.com/u/7710864/data/reviews-apr29.csv"
fileUrl2 <- "https://dl.dropboxusercontent.com/u/7710864/data/solutions-apr29.csv"
download.file(fileUrl1,destfile="./data/reviews.csv",method="curl")
download.file(fileUrl2,destfile="./data/solutions.csv",method="curl")
reviews <- read.csv("./data/reviews.csv"); solutions <- read.csv("./data/solutions.csv")
head(reviews,2)

grep("Alameda",cameraData$intersection)
table(grepl("Alameda",cameraData$intersection)) ##grep logical...returns vector of T and F
cameraData2 <- cameraData[!grepl("Alameda",cameraData$intersection),]
grep("Alameda",cameraData$intersection,value=TRUE) ##gives out the value

library(stringr)
nchar("Jeffrey Leek")
paste0("Jeffrey","Leek") ##paste with no spcae in between
str_trim("Jeff      ") ##trims the white spaces at the start and end of the string

###regular expression
##literals are where we need exact match
##^i think will match any line starting with "I think"
##morning$ will match any line ending with morning
##[] is called character class
##[Bb][Uu][Ss][Hh] will match any upper and lower case combination in word "bush"
##^[Ii] am  will match ^I am or ^i am at the start of the line
##^[0-9][a-zA-Z] will match anything like "[numeric][Letter]) at the start of the line
##[^?.]$...$ means matching end of the line..^ inside [] means not matching anything after ^
##hence it will match anything where last character of the line is not ? or .
##special character "."...means any one character..hence 9.11 will match anything 9-11 or 9a11 or 9111 etc
##metacharacte "|" means OR...so fire|flood will match any line containing fire or flood in it
##^[Gg]ood|[Bb]ad meaning "good or Good at the start of the line" or "Bad or bad anywhere in the line"
##^([Gg]ood|[Bb]ad) good or Good or Bad or bad at the start of the line"
##[Gg]eorge( [Ww]\.)? [Bb]ush...? after paranthesis is optional part..so it will match 
##george or George followed by W or blank or . and then Bush or bush.
##adding backslash here means dont consider "." to be special character
##"*" meaning search anything anynumber or times..."+" atleast once
##(.*) matching a line with paranthesis with anything inside it
##[0-9]+ (.*)[0-9]+ matches anynumber atleast once followed by anything 
##then followed by any number atleast once
##{ and } are referred to as interval quantifiers; the let us specify the minimum 
##and maximum number of matches of an expression
##[Bb]ush( +[^ ]+ +){1,5} debate





