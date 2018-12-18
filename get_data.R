library(jsonlite)
library(dplyr)
library(RCurl)
library(tidyr)
library(stringr)
library(data.table)
setwd("~/r-studio-workspace/bitcoin/liquid")

load(file="./data/liquid_blocks.RData")
blocks$height <- as.numeric(blocks$height)
stop <- max(blocks$height)
start <- as.numeric(getURL("https://blockstream.info/liquid/api/blocks/tip/height"))
while (start > stop){
   test <- fromJSON(paste0("https://blockstream.info/liquid/api/blocks/", start))
   if (nrow(blocks)==0) blocks <- test
   else blocks <- rbind(blocks, test)
   start <- min(blocks[unlist(blocks$height)>stop, ]$height)-1
   print(start)
   Sys.sleep(0.1)
}
blocks$id <- sapply(lapply(blocks$id, `[[`, 1), as.character)
blocks <- blocks[str_length(blocks$id)==64, ]
blocks <- unique(blocks)
save(blocks, file="./data/liquid_blocks.RData")

load(file="./data/liquid_blocks.RData")
load(file="./data/liquid_transactions.RData")
newTransactions = data.frame()
for (row in max(transactions$heigh+1):max(blocks$heigh)) {
   if (!is.na(blocks[row, ]$id))
      url <- paste0("https://blockstream.info/liquid/api/block/",blocks[row, ]$id,"/txs")
   else 
      print(paste0("--- Missing height ",row))
   print(url)
   test <- fromJSON(url)
   test$block <- blocks[row, ]$id
   if (nrow(newTransactions)==0) newTransactions <- test
   else newTransactions <- rbind(newTransactions, test)
   Sys.sleep(0.1)
}

newTransactions$vin_txid <- sapply(lapply(newTransactions$vin, `[[`, c("txid")), as.character)
newTransactions$vin_is_pegin <- sapply(lapply(newTransactions$vin, `[[`, c("is_pegin")), `%in%`, x = TRUE)
newTransactions$vin_is_coinbase <- sapply(lapply(newTransactions$vin, `[[`, c("is_coinbase")), `%in%`, x = TRUE)
#newTransactions$vin_issuance <- sapply(lapply(newTransactions$vin, "[[", c("issuance")), `paste`)

newTransactions$vout_is_pegout <- FALSE
newTransactions$vout_is_pegout[sapply(lapply(lapply(newTransactions$vout, `[[`, c("pegout")),"is.na"), `%in%`, x = FALSE)] <- TRUE

newTransactions$vout_type <- lapply(newTransactions$vout, `[[`, c("scriptpubkey_type"))
newTransactions$op_return <- sapply(newTransactions$vout_type, `%in%`, x = "op_return")
newTransactions <-  merge(newTransactions, blocks[c("id","height")], by.x="block", by.y="id")

transactions <- rbind(newTransactions, transactions)

#transactions$vout_is_pegout <- FALSE
#transactions$vout_is_pegout[sapply(lapply(lapply(transactions$vout, `[[`, c("pegout")),"is.na"), `%in%`, x = FALSE)] <- TRUE

transactions <- unique(transactions)
transactions$vin_is_pegin <- as.logical(transactions$vin_is_pegin)
transactions$vin_is_coinbase <- as.logical(transactions$vin_is_coinbase)
transactions$height <- as.numeric(transactions$height)
transactions$size <- as.numeric(transactions$size)
transactions$fee <- as.numeric(transactions$fee)
save(transactions, file="./data/liquid_transactions.RData")


load(file="./data/liquid_transactions.RData")
tx_op_return <- transactions[!transactions$vin_is_coinbase & !transactions$vin_is_pegin & !transactions$vout_is_pegout & transactions$op_return, ]

get_text <- function(x){
   a <- x
   tex <- ""
   if("scriptpubkey_asm" %in% colnames(a)){
      try({
         a$tmp <- strsplit(a$scriptpubkey_asm, " ")
         flag <- lapply(a$tmp, `[`, 1) == "OP_RETURN"
         text <- lapply(a$tmp, `[`, 3) 
         hex <- unlist(text[flag & !is.na(flag)])
         if (length(hex) == 1){
            if ( !is.na(hex) & (nchar(hex)>4) ){
               h <- sapply(seq(1, nchar(hex), by=2), function(x) substr(hex, x, x+1))
               tex <- rawToChar(as.raw(strtoi(h, 16L)))
            }
         }
      })
   }
   return(tex)
}

get_hex <- function(x){
   a <- x
   tex <- ""
   if("scriptpubkey_asm" %in% colnames(a)){
      try({
         a$tmp <- strsplit(a$scriptpubkey_asm, " ")
         flag <- lapply(a$tmp, `[`, 1) == "OP_RETURN"
         text <- lapply(a$tmp, `[`, 3) 
         hex <- unlist(text[flag & !is.na(flag)])
         if (length(hex) == 1){
            if ( !is.na(hex) & (nchar(hex)>4) ){
               tex <- hex
            }
         }
      })
   }
   return(tex)
}

tx_op_return$text <- sapply(tx_op_return$vout, "get_text")
tx_op_return$text <- gsub('[^[:print:]]+', '', tx_op_return$text)
tx_op_return$hex <- sapply(tx_op_return$vout, "get_hex")

save(tx_op_return, file="./data/liquid_transactions_op_return.RData")

