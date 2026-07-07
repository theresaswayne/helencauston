//@ File (label="Input directory",style="directory") inputdir
//@ File (label="Output directory",style="directory") outputdir
//@ string (label="File type", choices={".czi",".nd2",".ome.tiff",".tif"}, style="listBox") Type

//Put ratio image in the input folder and the mask image in the "x-Masks" folder.

list = getFileList(inputdir);

for (i=0; i<list.length; i++) {
    showProgress(i+1, list.length);
    filename = inputdir+File.separator + list[i];
    if(Type == ".ome.tiff" ){
    Fname_temp = File.getNameWithoutExtension(filename);
    Fname = File.getNameWithoutExtension(Fname_temp);   
    }
    else{
     Fname = File.getNameWithoutExtension(filename);   	
    	}
    
    coreFname = substring(Fname, 0, lengthOf(Fname)-5);
    	
    Folder_Mask = inputdir+File.separator+ "x-Masks";
    maskfile = Folder_Mask +File.separator+coreFname + "mask.tif";
    
    print("\\Clear");
	roiManager("reset");
	roiManager("Show None");
	run("Clear Results");
	run("Collect Garbage");

    print(filename);
    print(list[i]);

	 if (endsWith(filename, Type)) {
        setBatchMode(0);
        roiManager("reset");
        run("Bio-Formats Importer", "open=" + filename + " autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");
        run("Select None");
        ratio_image=getImageID();
        Stack.getDimensions(width, height, ch, slices, frames);
        imagewidth = width;
        imageheight = height;
        imageZstack = slices;
        
        run("Set Measurements...", "bounding redirect=None decimal=9");
		run("Measure");
		px = width / getResult("Width");
		
		run("Bio-Formats Importer", "open=" + maskfile + " autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");
        run("Select None");
		mask_image=getImageID();
		run("Multiply...", "value=255 stack");
		selectImage(mask_image);
		run("3D Manager");
		Ext.Manager3D_Segment(128, 255);
		mask_seg=getImageID();
		saveAs("Tiff", outputdir+File.separator+Fname+"-3dseg.tif");
		selectImage(mask_seg);
		Ext.Manager3D_AddImage;
		waitForUser("Check the mito segmentation. Remove dead cells. Press OK when you are done.");
    	Ext.Manager3D_SelectAll;
		Ext.Manager3D_Save(outputdir+File.separator+Fname+"-mito-Roi3D.zip");
		selectImage(ratio_image);
		Ext.Manager3D_SelectAll;
		Ext.Manager3D_Measure;
		Ext.Manager3D_SaveResult("M", outputdir+File.separator + Fname +"-3D_measure.csv");
		Ext.Manager3D_Quantif;
		Ext.Manager3D_SaveResult("Q", outputdir+File.separator + Fname +"-3D_quantif.csv");
		Ext.Manager3D_CloseResult("M");
		Ext.Manager3D_CloseResult("Q");
		Ext.Manager3D_Reset();
		Ext.Manager3D_Close();
		if (isOpen("Exception")){
			close("Exception");
		}
		close("*");
		
}

}
