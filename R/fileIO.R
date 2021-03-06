
# # ' @title an empty file to import necessary libraries 
#' @import limma MASS
# # ' @name _empty
NULL


#'@title S3 function to read/import the data from a text file
#'@description \code{importTextData} reads/imports the data from a text file
#'@details This function take a text format file as input.
#'	 The file has a fixed format. It assumes the input file is
#'	generated by the protoarray software (prospector).
#'	Please see the sample data.
#'
#'@param dataFilePath string path to the file containing the text formatted input data.
#'				This is a tab-delimited file exported from the software reading
#'               the arrays. It has both gene data and control data in one.
#'@param TargetFile string path to a text file holding the meta data for the array. 
#'				Please check the template
#'@param start.data numeric the line number indicating where the data section starts
#'@param nrows.data numeric number of rows for the data section
#'@param start.control numeric the line number indicating where the control data section starts
#'@param nrow.control numeric the number of rows for the control section
#'@param aggregation string indicating which type of duplicate aggregation should be performed. 
#			If "min" is chosen, the value for the corresponding feature will be the minimum of both. 
#			If "arithMean" is chosen, the arithmetic mean will be computed. 
#			If "genMean" is chosen, the geometric mean will be computed.
#			The default is "min" (optional).
#'@param as.is boolean TRUE by default,for reading the text file
#'@param header boolean TRUE by default, for reading the text file
#'@param sep char "tab-delimited (tab)" by default, for reading the text file
#'@param na.strings string "" by default, for reading the text file
#'@param quote char "" (no quote) by default,  for reading the text file
#'@return an ELISTlist object containing both the data and control
#@seealso
#'@examples
#'	datapath<-system.file("extdata", package="ARPPA")
#'	targets <- list.files(system.file("extdata", package="ARPPA"),
#'		 pattern = "targets_text_Batch1", full.names=TRUE) 

#'	elist2<-importTextData(dataFilePath=datapath, targetFile=targets, start.data=51, nrows.data=18803-53,
#'				start.control=18803, nrows.control=23286,aggregation="geoMean",
#'				as.is=TRUE, header=TRUE,sep="\t",na.strings="", quote="")
#'
#'@export
importTextData<-function(dataFilePath=NULL, targetFile=NULL, start.data=NULL, nrows.data=NULL,
				start.control=NULL, nrows.control=NULL,aggregation="geoMean",
				as.is=TRUE, header=TRUE,sep="\t",na.strings="", quote="")
		{
			 if (is.null(dataFilePath) || is.null(targetFile)) {
				stop("ERROR: Not all mandatory arguments have been defined!")
				}
			if (start.data<=0|| nrows.data<=0||start.control<=0||nrows.control<=0) {
				stop("ERROR: Not all mandatory arguments have been defined!")
				}
			if(aggregation!="geoMean"&&aggregation!="arithMean"&&aggregation!="min")
			{
				cat("Warning:Unknow aggregation type, use default (min)!\n")
				aggregation="min";
			}
			#now read the data first
			cat("reading target files for \"", targetFile, "\"...\n")
			flush.console();
			targetRd<-read.table(targetFile, sep="\t", header=TRUE, as.is=TRUE, na.strings="", quote="");
			cat("Done!\n")
			original_path<-getwd()
			setwd(dataFilePath);#,
			fileNames<-targetRd[,"FileName"]
			
			for(i in c(1:length(fileNames)))
			{
				cat("reading data files for ", fileNames[i], "...\n")
				flush.console();
				dataRd<-read.table(fileNames[i], sep="\t", header=TRUE, skip=51, nrows=18803-53,as.is=TRUE, na.strings="", quote="");
				ctrDataRd<-read.table(fileNames[i], sep="\t", header=TRUE, skip=18803, nrows=-1,as.is=TRUE, na.strings="", quote="");

				
				#put them together
				if(i==1)
				{
					#control data
					ctrData_signal<-data.frame(ctrDataRd[,'Signal']);
					ctrData_background<-data.frame(ctrDataRd[,'Background']);
					#sample data
					dataAll_signal<-data.frame(dataRd[,'Signal']);
					dataAll_background<-data.frame(dataRd[,'Background']);
					
				}
				else
				{
					#control data
					ctrData_signal<-cbind(ctrData_signal,ctrDataRd[,'Signal']);
					ctrData_background<-cbind(ctrData_background,ctrDataRd[,'Background']);
					
					#sample data
					dataAll_signal<-cbind(dataAll_signal, dataRd[,'Signal']);
					dataAll_background<-cbind(dataAll_background, dataRd[,'Background']);
					
				}				
			}#end of read data
			cat("Done!\n")
			sampleNames<-targetRd[,"ArrayID"]
			colnames(dataAll_signal)<- sampleNames;
			colnames(dataAll_background)<- sampleNames;
			colnames(ctrData_signal)<- sampleNames;
			colnames(ctrData_background)<- sampleNames;

			##aggregation,summary/average the duplicates
			sum_index<-seq(1,length(dataRd[,1]),2);
			#dataAll_signal<-c();
			#dataAll_background<-c();
			csum_index<-seq(1,length(ctrDataRd[,1]),1);
			if(aggregation=="geoMean")
			{
				#cat("geonMean\n");
				dataAll_signal<-exp((log(dataAll_signal[sum_index,])+log(dataAll_signal[sum_index+1,]))/2)
				dataAll_background<-exp((log(dataAll_background[sum_index,])+log(dataAll_background[sum_index+1,]))/2)
				#cat("length dataAll:", dim(dataAll_signal
			}
			else if(aggregation=="arithMean")
			{
				cat("arithMean\n");
				dataAll_signal<-(dataAll_signal[sum_index,]+dataAll_signal[sum_index+1,])/2
				dataAll_background<-(dataAll_background[sum_index,]+dataAll_background[sum_index+1,])/2
			}
			else #default min
			{
				cat("min\n");
				dataAll_temp1<-(dataAll_signal[sum_index,])
				dataAll_temp2<-(dataAll_signal[sum_index+1,])
				dataAll_temp1[dataAll_temp1>dataAll_temp2]<-dataAll_temp2[dataAll_temp1>dataAll_temp2]
				dataAll_signal<-dataAll_temp1
				
				dataAll_temp1<-(dataAll_background[sum_index,])
				dataAll_temp2<-(dataAll_background[sum_index+1,])
				dataAll_temp1[dataAll_temp1>dataAll_temp2]<-dataAll_temp2[dataAll_temp1>dataAll_temp2]
				dataAll_background<-dataAll_temp1
			}
			
			#now use the last readin file to create gene info frame
			genes<-dataRd[sum_index,c('Block','Column','Row','Protein.Amount','Description')];

			genes$Name<-paste("Hs~",dataRd[sum_index,'Database.ID'],"~uORF:",dataRd[sum_index,'Ultimate.ORF.ID'],sum_index,sep="");
			genes$ID<-paste("HA20251~",dataRd[sum_index,'Array.ID'],sep="");


			cgenes<-ctrDataRd[csum_index,c('Block','Column','Row')];
			cgenes$Description<-rep('Control',length(csum_index))
			cgenes$Name<-ctrDataRd[csum_index,'ControlGroup'];
			cgenes$ID<-paste("HA20251~",ctrDataRd[csum_index,'ID'],sep="");
			#cgenes$
			dataAll_signal<-as.matrix(dataAll_signal)
			dataAll_background<-as.matrix(dataAll_background)
			ctrData_signal<-as.matrix(ctrData_signal);
			ctrData_background<-as.matrix(ctrData_background);

			#create a target object dataframe
			#targets<-data.frame(ArrayID=sampleNames,FileName=fileNames,Group=group, Batch=rep('B1',length(sampleNames)),
			#					Data=rep('11.21.2015',length(sampleNames)),Array=c(1:length(sampleNames)),SerumID=sampleNames);
			#this is part of information for organization of section in the array
			printer<-list(ngrid.r=12, ngrid.c=4,nspot.r=22, nspot.r=22);					
								
			el<-list(E=dataAll_signal, Eb=dataAll_background, targets=targetRd, genes=genes,
					source="genepix.median", printer=printer, C=ctrData_signal, Cb=ctrData_background, cgenes=cgenes);
			setwd(original_path);		
			elist2<-new("EListRaw", el)
			##........now we have object, do the jobs
		}#end of function###########

#import GPR Data
#'@title import GPR file data
#'@description read the design file to get the information for GPR data and 
#'	then import the GPR files included in the design file. 
#'@details this follows the style of PAA (PotoArray Analyzer). It reads in the design file and then
#'	all the GPR files included in the design will be read in. Under the cover, it calls 
#'	the  limma's function read.maimages(). Please make sure that you are reading "ProtoArray" GPR files, 
#'	since this is only type that currently supported.
#'
#'@param dir.GPR character string to indicate the path to the GPR files. Note: it is better
#'	to keep the design file in the same folder, but they could be in different location.
#'	In the latter case, you need to specify a full path and file name in the design.file.
#'@param design.file character string to indicate the design file name. We don't use
#'	the path.GPR to guide the reading of the design.file, you might need to specify 
#'	a full path to it, if it is not in the current working directory. 
#'@param type character string to indicate the type of the protein Array. currently, only
#'	available type is "ProtoArray".
#'@param array.columns list of string to be passed to the limma's function to 
#	indicate what field to be use reading as the expressions. 
#'@param array.annotation a vector of strings indicating the columns to be
#'	read in from GPR files.
#'@param description character string to indicating the column name, which 
#'	holding the description information, when there is column "Description" 
#'	available in the data. Importantly, we read this column for inforamtion
#'	indicating whether a protein is a feature, control or empty/to discarded. 
#'
#'@param description.features character string containing a regular expression identifying feature sports. 
#'@param description.discard character string containing a regular expression indicating protein spots to be discarded.

#'@return an EListRaw object holding the feature and control protein expression as well as other 
#'	annotations.
#'
#'@export 
importGPR <- function(dir.GPR=".", design.file, #the design file contains all the information about gpr files plus other information
		type=c("ProtoArray"), #this is the only implementation so far
		#aggregation="none", #never do aggration in reading the 
		array.columns=list(E="F635 Median", Eb="B635 Median"),
		array.annotation=c("Block", "Column", "Row", "Description", "Name", "ID"),
		description, description.features, description.discard)
{

    if( missing(design.file) ) {
        stop("ERROR: please specify design file!")
    }
    if(!missing(description) && missing(description.features)) {
        stop(paste0("ERROR: If 'description' is defined 'description.features'",
        " is mandatory!"))
    }
    if(!missing(description) && missing(description.discard)) {
        stop(paste0("ERROR: If 'description' is defined 'description.discard' ",
        "is mandatory!"))
    }
    design <- readTargets(design.file)
    elist.tmp <- read.maimages(files=design, path=dir.GPR,
      source="genepix.median", columns=array.columns,
      annotation=array.annotation)
    if(length(setdiff(array.annotation, colnames(elist.tmp$genes))) > 0){
        warning(paste0("Columns were not found in GPR files: ",
        paste(setdiff(array.annotation, colnames(elist.tmp$genes)),
        collapse=", ")),
        ".\n Please check your GPR files to make sure the data are complete.\n ",
        "Note: we will read Description information if it is missing and you have specified an alternative field.\n ",
        sep="")
    }
     
    # For ProtoArrays: construct missing column 'Description' from the column
    # 'Name'. Alternatively, another column in elist$genes and other
    # regular expressions can be specified.  
    if(is.null(elist.tmp$genes$Description) && type=="ProtoArray"){
        elist.tmp$genes <- cbind(elist.tmp$genes,
          rep("NA",nrow(elist.tmp$genes)), stringsAsFactors=FALSE)
        colnames(elist.tmp$genes)[ncol(elist.tmp$genes)] <- "Description"
        features <- grep("^Hs~", elist.tmp$genes$Name)
        controls <- grep("^Hs~", elist.tmp$genes$Name, invert=TRUE)
        empty <- grep("(^Empty|^EMPTY)", elist.tmp$genes$Name) 
        #controls <-
        #  grep("(^HumanIg|^Anti-HumanIg|^V5|Anti-human-Ig|V5Control)",
        #  elist.tmp$genes$Name)
        elist.tmp$genes$Description[features] <- "Feature"
        elist.tmp$genes$Description[controls] <- "Control"
        elist.tmp$genes$Description[empty] <- "Empty"  
    }else if(is.null(elist.tmp$genes$Description) && !missing(description)
      && !missing(description.features) && !missing(description.discard)){
      
        elist.tmp$genes <- cbind(elist.tmp$genes,
          rep("NA",nrow(elist.tmp$genes)), stringsAsFactors=FALSE)
        colnames(elist.tmp$genes)[ncol(elist.tmp$genes)] <- "Description"
        
        features <- grep(description.features, elist.tmp$genes[,description])
        controls <- grep(description.features, elist.tmp$genes[,description],
          invert=TRUE)
        empty <- grep(description.discard, elist.tmp$genes[,description])
        
        elist.tmp$genes$Description[features] <- "Feature"
        elist.tmp$genes$Description[controls] <- "Control"
        elist.tmp$genes$Description[empty] <- "Empty"    
    } 

    # If no match, grep will return 'integer(0)' resulting in an empty elist$E
    # in the following lines. Hence the following if-statements are necessary:
	elist<-elist.tmp; #this is necessary, if neither of the following if clauses give any results.
    if(any(grep("(^Empty$|^EMPTY$|^NA$)", elist.tmp$genes$Description))){
      elist.tmp <- elist.tmp[-grep("(^Empty$|^EMPTY$|^NA$)",elist.tmp$genes$Description),]
    }
    if(any(grep("(^Control$|^CONTROL$)", elist.tmp$genes$Description))){
      elist <- elist.tmp[-grep("(^Control$|^CONTROL$)", elist.tmp$genes$Description),]
    }

    colnames(elist$E) <- design$ArrayID
    colnames(elist$Eb) <- colnames(elist$E)

    #if(aggregation=="none"){
    #    cat("No aggregation performed.\n")
    #}else if(array.type=="ProtoArray" && aggregation=="min"){
    #    row.len <- nrow(elist$E)
    #    col.len <- ncol(elist$E)
    #    tmp.col.len <- (row.len*col.len)/2
    #    elist$E[row(elist$E)[,1]%%2==1] <-
    #      matrix(apply(matrix(elist$E,2,tmp.col.len),2,min),row.len/2,col.len)
    #    elist <- elist[-row(elist)[,1]%%2==1,]
    #}else if(array.type=="ProtoArray" && aggregation=="mean"){
    #    elist$E[row(elist$E)[,1]%%2==1,] <-
    #      (elist$E[row(elist$E)[,1]%%2==1,]+elist$E[row(elist$E)[,1]%%2==0,])/2
    #    elist <- elist[-row(elist)[,1]%%2==1,]
    #}else{
    #    stop(paste0("ERROR: This aggregation approach is for the specified ",
    #    "array type not supported.\nPlease contact the PAA maintainer for a ",
    #    "possible implementation of the requested agrregation approach for ",
    #    "this array type."))
    #}
    
    # Adding controls data to the EListRaw object for ProtoArrays in order to
    # use it for rlm normalization.
    if(type == "ProtoArray"){
        elist.tmp <-
          elist.tmp[grep("^Control$", elist.tmp$genes$Description),]
        
		elist.tmp$genes$Name <-
          gsub('^([0-9A-Za-z_-]*)~(.*)', '\\1', elist.tmp$genes$Name)
        
		elist$C <- elist.tmp$E
        elist$Cb <- elist.tmp$Eb
        elist$cgenes <- elist.tmp$genes
        colnames(elist$C) <- colnames(elist$E)
        colnames(elist$Cb) <- colnames(elist$E)
    }else if(type != "ProtoArray" && !missing(description)){
        elist.tmp <-
          elist.tmp[grep("^Control$", elist.tmp$genes$Description),]
        elist.tmp$genes$Name <-
          gsub('^([0-9A-Za-z_-]*)~(.*)', '\\1', elist.tmp$genes$Name)
        elist$C <- elist.tmp$E
        elist$Cb <- elist.tmp$Eb
        elist$cgenes <- elist.tmp$genes
        colnames(elist$C) <- colnames(elist$E)
        colnames(elist$Cb) <- colnames(elist$E)
    }
    
    # Adding this custom component in order to check the microarray type in
    # type-specific functions
    elist$array.type <- type
    
    return(elist)
}#####loadData###############		
		
# fucntion to do background correct
# this is a wrapper, since the original background correction function
# for regular array only work on the target array and nothing to do
# for protoarray control proteins.
#'@title S3 function to correct background intensities
#'@description backgrount correct microarray intensities
#'@details This function is a wrapper to call limma package backgroundCorrect function.
#'	It take in a EListRaw or RGList and pass it to limma function. In case the object
#'	is protoArray EListRaw, we will perform extra backgroundCorrect on control 
#'	proteins. To do this, we simply swap the control and target protein field
#' 	and call twice the limma function. See details in backgroundCorrect of limma
#'	package.
#'
#'@param RG a numeric matrix, EListRaw or RGList object.
#'@param E	numeric matrix containing foreground intensities.
#'@param Eb	numeric matrix containing background intensities.
#'@param method	character string specifying correction method. Possible values are 
#' "auto", "none", "subtract", "half", "minimum", "movingmin", "edwards" or "normexp". 
#' If RG is a matrix, possible values are restricted to "none" or "normexp". 
#'	The default "auto" is interpreted as "subtract" if background intensities 
#' are available or "normexp" if they are not.
#'@param offset	numeric value to add to intensities
#'@param printer a list containing printer layout information, 
#'	see PrintLayout-class. Ignored if RG is a matrix.
#'@param normexp.method character string specifying parameter estimation 
#' strategy used by normexp, ignored for other methods. Possible values are 
#' "saddle", "mle", "rma" or "rma75".
#'@param verbose   logical. If TRUE, progress messages are sent to standard output
#'
#'@return an ELISTlist object containing corrected
#@seealso
# #'@examples
# #'	datapath<-system.file("extdata", package="ARPPA")
# #'	targets <- list.files(system.file("extdata", package="ARPPA"),
# #'		 pattern = "targets_text_Batch1", full.names=TRUE) 

# #'	elist2<-importTextData(dataFilePath=datapath, targetFile=targets, start.data=51, nrows.data=18803-53,
# #'				start.control=18803, nrows.control=23286,aggregation="geoMean",
# #'				as.is=TRUE, header=TRUE,sep="\t",na.strings="", quote="")
# #'
#'@export
bc<-function(RG, method="normexp", offset=0, printer=RG$printer,
                  normexp.method="saddle", verbose=TRUE)
{
	#first correct target field
	RG<-backgroundCorrect(RG,method=method, offset=offset, printer=printer
		,normexp.method=normexp.method, verbose=verbose
		)
	#now check to see whether we need to do more
	if(class(RG)=="EListRaw"&&RG$array.type=="ProtoArray"){
		RG_temp<-RG
		RG_temp$E<-RG$C
		RG_temp$Eb<-RG$Cb
		RG_temp<-backgroundCorrect(RG_temp,method=method, offset=offset, printer=printer
		,normexp.method=normexp.method, verbose=verbose
		)
		#change things back
		RG$C<-RG_temp$E
		RG$Cb<-RG_temp$Eb
		#now switch
	}
	RG
}				  
##############testing area###########
