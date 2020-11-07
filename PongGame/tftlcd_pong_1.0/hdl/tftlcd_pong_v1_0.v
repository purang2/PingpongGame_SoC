
`timescale 1 ns / 1 ps

	module tftlcd_pong_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S01_AXI
		parameter integer C_S01_AXI_DATA_WIDTH	= 32,
		parameter integer C_S01_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
       input wire CLK,                                 // = 25MHz
       input wire nRESET,                                //  ?
       output wire TCLK,                   // TFT needs <12.5MHz>
       output wire Hsync,       // TFT-LCD HSYNC
       output wire Vsync,	     // TFT-LCD VSYNC
       output wire DE_out,	 // TFT-LCD Data enable ( Alaways "1" )
       output wire [7:3] R,            
       output wire [7:2] G,            
       output wire [7:3] B,         
       output Tpower,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S01_AXI
		input wire  s01_axi_aclk,
		input wire  s01_axi_aresetn,
		input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s01_axi_awaddr,
		input wire [2 : 0] s01_axi_awprot,
		input wire  s01_axi_awvalid,
		output wire  s01_axi_awready,
		input wire [C_S01_AXI_DATA_WIDTH-1 : 0] s01_axi_wdata,
		input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb,
		input wire  s01_axi_wvalid,
		output wire  s01_axi_wready,
		output wire [1 : 0] s01_axi_bresp,
		output wire  s01_axi_bvalid,
		input wire  s01_axi_bready,
		input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s01_axi_araddr,
		input wire [2 : 0] s01_axi_arprot,
		input wire  s01_axi_arvalid,
		output wire  s01_axi_arready,
		output wire [C_S01_AXI_DATA_WIDTH-1 : 0] s01_axi_rdata,
		output wire [1 : 0] s01_axi_rresp,
		output wire  s01_axi_rvalid,
		input wire  s01_axi_rready
	);
// Instantiation of Axi Bus Interface S01_AXI
	tftlcd_pong_v1_0_S01_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)
	) tftlcd_pong_v1_0_S01_AXI_inst (
	
	   // User Port
	    .CLK(CLK),             
        .nRESET(nRESET),
        .TCLK(TCLK),
        .Hsync(Hsync),
        .Vsync(Vsync),
        .DE_out(DE_out),
        .R(R),
        .G(G),
        .B(B),
        .Tpower(Tpower),
        // User Port End
        
		.S_AXI_ACLK(s01_axi_aclk),
		.S_AXI_ARESETN(s01_axi_aresetn),
		.S_AXI_AWADDR(s01_axi_awaddr),
		.S_AXI_AWPROT(s01_axi_awprot),
		.S_AXI_AWVALID(s01_axi_awvalid),
		.S_AXI_AWREADY(s01_axi_awready),
		.S_AXI_WDATA(s01_axi_wdata),
		.S_AXI_WSTRB(s01_axi_wstrb),
		.S_AXI_WVALID(s01_axi_wvalid),
		.S_AXI_WREADY(s01_axi_wready),
		.S_AXI_BRESP(s01_axi_bresp),
		.S_AXI_BVALID(s01_axi_bvalid),
		.S_AXI_BREADY(s01_axi_bready),
		.S_AXI_ARADDR(s01_axi_araddr),
		.S_AXI_ARPROT(s01_axi_arprot),
		.S_AXI_ARVALID(s01_axi_arvalid),
		.S_AXI_ARREADY(s01_axi_arready),
		.S_AXI_RDATA(s01_axi_rdata),
		.S_AXI_RRESP(s01_axi_rresp),
		.S_AXI_RVALID(s01_axi_rvalid),
		.S_AXI_RREADY(s01_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
