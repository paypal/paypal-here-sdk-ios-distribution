namespace RetailSDKTestApp.WinForms.Net4
{
    partial class MainPage
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.label1 = new System.Windows.Forms.Label();
            this.txtAmount = new System.Windows.Forms.TextBox();
            this.btnCharge = new System.Windows.Forms.Button();
            this.txtSdkToken = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.btnInitializeMerchant = new System.Windows.Forms.Button();
            this.lblStatus = new System.Windows.Forms.Label();
            this.btnExtractReaderLogs = new System.Windows.Forms.Button();
            this.btnReset = new System.Windows.Forms.Button();
            this.cbTestMode = new System.Windows.Forms.CheckBox();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(190, 188);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(43, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Amount";
            // 
            // txtAmount
            // 
            this.txtAmount.Location = new System.Drawing.Point(264, 185);
            this.txtAmount.Name = "txtAmount";
            this.txtAmount.Size = new System.Drawing.Size(175, 20);
            this.txtAmount.TabIndex = 1;
            this.txtAmount.Text = "1.00";
            //
            // btnCharge
            //
            this.btnCharge.Location = new System.Drawing.Point(264, 223);
            this.btnCharge.Name = "btnCharge";
            this.btnCharge.Size = new System.Drawing.Size(75, 23);
            this.btnCharge.TabIndex = 2;
            this.btnCharge.Text = "Charge";
            this.btnCharge.UseVisualStyleBackColor = true;
            this.btnCharge.Click += new System.EventHandler(this.btnCharge_Click);
            //
            // txtSdkToken
            //
            this.txtSdkToken.Location = new System.Drawing.Point(264, 147);
            this.txtSdkToken.Name = "txtSdkToken";
            this.txtSdkToken.Size = new System.Drawing.Size(175, 20);
            this.txtSdkToken.TabIndex = 4;
            this.txtSdkToken.MouseClick += new System.Windows.Forms.MouseEventHandler(this.txtSdkToken_MouseClick);
            //
            // label2
            //
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(190, 150);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(38, 13);
            this.label2.TabIndex = 3;
            this.label2.Text = "Token";
            //
            // btnInitializeMerchant
            //
            this.btnInitializeMerchant.Location = new System.Drawing.Point(456, 144);
            this.btnInitializeMerchant.Name = "btnInitializeMerchant";
            this.btnInitializeMerchant.Size = new System.Drawing.Size(71, 23);
            this.btnInitializeMerchant.TabIndex = 5;
            this.btnInitializeMerchant.Text = "Set token";
            this.btnInitializeMerchant.UseVisualStyleBackColor = true;
            this.btnInitializeMerchant.Click += new System.EventHandler(this.btnInitializeMerchant_Click);
            //
            // lblStatus
            //
            this.lblStatus.AutoSize = true;
            this.lblStatus.Location = new System.Drawing.Point(252, 275);
            this.lblStatus.Name = "lblStatus";
            this.lblStatus.Size = new System.Drawing.Size(113, 13);
            this.lblStatus.TabIndex = 7;
            this.lblStatus.Text = "Awaiting Initialization...";
            //
            // btnExtractReaderLogs
            //
            this.btnExtractReaderLogs.Enabled = false;
            this.btnExtractReaderLogs.Location = new System.Drawing.Point(264, 304);
            this.btnExtractReaderLogs.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.btnExtractReaderLogs.Name = "btnExtractReaderLogs";
            this.btnExtractReaderLogs.Size = new System.Drawing.Size(175, 24);
            this.btnExtractReaderLogs.TabIndex = 8;
            this.btnExtractReaderLogs.Text = "Extract reader logs";
            this.btnExtractReaderLogs.UseVisualStyleBackColor = true;
            this.btnExtractReaderLogs.Click += new System.EventHandler(this.btnExtractReaderLogs_Click);
            // 
            // btnReset
            // 
            this.btnReset.Location = new System.Drawing.Point(533, 144);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(97, 23);
            this.btnReset.TabIndex = 8;
            this.btnReset.Text = "Restore default";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.btnReset_Click);
            // 
            // cbTestMode
            // 
            this.cbTestMode.AutoSize = true;
            this.cbTestMode.Location = new System.Drawing.Point(264, 345);
            this.cbTestMode.Name = "cbTestMode";
            this.cbTestMode.Size = new System.Drawing.Size(77, 17);
            this.cbTestMode.TabIndex = 9;
            this.cbTestMode.Text = "Test Mode";
            this.cbTestMode.UseVisualStyleBackColor = true;
            this.cbTestMode.CheckedChanged += new System.EventHandler(this.cbTestMode_CheckedChanged);
            // 
            // MainPage
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(717, 442);
            this.Controls.Add(this.cbTestMode);
            this.Controls.Add(this.btnExtractReaderLogs);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.lblStatus);
            this.Controls.Add(this.btnInitializeMerchant);
            this.Controls.Add(this.txtSdkToken);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.btnCharge);
            this.Controls.Add(this.txtAmount);
            this.Controls.Add(this.label1);
            this.Name = "MainPage";
            this.Text = "WinForms Retail SDK (Net4)";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox txtAmount;
        private System.Windows.Forms.Button btnCharge;
        private System.Windows.Forms.TextBox txtSdkToken;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button btnInitializeMerchant;
        private System.Windows.Forms.Label lblStatus;
        private System.Windows.Forms.Button btnExtractReaderLogs;
        private System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.CheckBox cbTestMode;
    }
}

