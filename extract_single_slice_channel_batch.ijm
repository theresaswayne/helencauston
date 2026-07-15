//@File(label = "Input directory", style = "directory") inputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".ome.tiff") fileSuffix
//@ int(label="Channel to extract", style = "spinner", value=3) Channel_1
//@ int(label="Slice to extract", style = "spinner", value = 11) Slice_1

// ImageJ/Fiji script to extract a single channel and slice 
//    from a batch of multichannel stacks
// 	Useful for pulling transmitted light image for Cellpose segmentation
// Theresa Swayne, 2026 with thanks to Emily Jie-Ning Yang for extension handling
// 
//  -------- Suggested text for acknowledgement -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// 	

// ---- Setup ----

while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
}
print("\\Clear"); // clear Log window

// keep track of time
startTime = getTime();

setBatchMode(true); // 2x faster performance
run("Bio-Formats Macro Extensions"); // support native microscope files


// ---- Run ----

print("Starting");

// Call the processFolder function, including the parameters collected at the beginning of the script

processFolder(inputDir, outputDir, fileSuffix, Channel_1, Slice_1);

// Clean up images and get out of batch mode

while (nImages > 0) { // clean up open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished in ", elapsedTime , " sec");


// ---- Functions ----

function processFolder(input, output, suffix, chan, slice) {

	// this function searches for files matching the criteria and sends them to the processFile function
	filenum = -1;
	print("Processing folder", input);

	// scan folder tree to find files with correct suffix
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		showProgress(i+1, list.length);
		if(File.isDirectory(input + File.separator + list[i])) {
			processFolder(input + File.separator + list[i], output, suffix, chan, slice); // handles nested folders
		}
		if(endsWith(list[i], suffix)) {
			filenum = filenum + 1;
			processFile(input, output, list[i], filenum, chan, slice); // passes the filename and parameters to the processFile function
		}
	}
} // end of processFolder function


function processFile(inputFolder, outputFolder, fileName, fileNumber, channel, slice) {
	
	// this function processes a single image
	
	path = inputFolder + File.separator + fileName;
	print("Processing file",fileNumber," at path" ,path);	
		 
	// determine the name of the file without extension -- support ome tiff
    if(endsWith(fileName, ".ome.tiff")){
	    basename_temp = File.getNameWithoutExtension(fileName);
	    basename = File.getNameWithoutExtension(basename_temp);
	    extension = ".ome.tiff";
    }
    else{
		dotIndex = lastIndexOf(fileName, ".");
	    basename = File.getNameWithoutExtension(basename);
		extension = substring(fileName, dotIndex);
    }

	print("File basename is",basename, "and extension is",extension );

	
	// open the file
	
	// --- option 1 -- open entire file and make a substack
	//run("Bio-Formats", "open=&path");
	//rename("orig"); // renaming avoids issues with complicated extensions

	//run("Make Substack...", "channels="+channel+" slices="+ slice);
	//substackName = "orig-1";
	//selectWindow(substackName);

	// --- option 2 --- open a subset directly
	run("Bio-Formats", "open=&path color_mode=Default series_1 specify_range c_begin=&channel c_end=&channel c_step=1 z_begin=&slice z_end=&slice z_step=1");
			
	// save the output
	outputName = basename + "_c"+channel+"_s"+slice+".tif";
	saveAs("tiff", outputFolder + File.separator + outputName);
	close();
	
	// clean up
	while (nImages > 0) { // clean up open images
		selectImage(nImages);
		close(); 
	}
} // end of processFile function


	