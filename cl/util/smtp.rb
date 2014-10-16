require 'net/smtp'
require 'time'

module ClUtil
  class Attachment
    def self.load_from_file(filename)
      data = nil
      File.open(filename, 'rb') do |f|
        data = f.read()
      end
      data = [data].pack("m*")
      Attachment.new(File.basename(filename), data)
    end

    attr_reader :name, :data

    def initialize(name, data)
      @name = name
      @data = data
    end
  end

  class Smtp
    attr_reader :attachments
    attr_accessor :from, :subj, :body, :extra_headers, :username, :password, :auth_type, :enable_starttls, :port

    def initialize(smtpsrv='localhost', port=25)
      @smtpsrv = smtpsrv
      @port = port
      @attachments = []
      @username = nil
      @password = nil
      @auth_type = :login
      @enable_starttls = false
    end

    def to
      @to
    end

    def to=(value)
      @to = [value].flatten
    end

    def sendmail
      msg = build_message
      @smtp = Net::SMTP.new(@smtpsrv, @port)
      start_tls_if_needed
      @smtp.start('localhost.localdomain', @username, @password, @auth_type) do |smtp|
        smtp.sendmail(msg, @from, @to)
      end
    end

    def start_tls_if_needed
      return if !@enable_starttls
      # require 'rubygems'
      # gem 'smtp_tls'
      # require 'smtp_tls'
      @smtp.enable_starttls
    end

    def content_type
      @body =~ /<html>/ ? "text/html" : "text/plain"
    end

    def build_message
      msg = format_headers
      boundary = create_boundary

      if !@attachments.empty?
        msg << [
          "Content-Type: multipart/mixed; boundary=\"#{boundary}\"\n",
          "\n",
          "This is a multi-part message in MIME format.\n",
          "\n"
        ]
      end

      if @body
        msg << [ "--#{boundary}\n" ] if !@attachments.empty?
        msg << [
          "Content-Type: #{content_type}; charset=\"iso-8859-1\"\n",
          "Content-Transfer-Encoding: 8bit\n",
          "\n",
          "#{@body}\n",
          "\n"
        ]
      end

      @attachments.each do |attachment|
        basename = attachment.name
        msg << [
          "--#{boundary}\n",
          "Content-Type: application/octet-stream; name=\"#{basename}\"\n",
          "Content-Transfer-Encoding: base64\n",
          "Content-Disposition: attachment; filename=\"#{basename}\"\n",
          "\n",
          "#{attachment.data}",  # no \n needed
          "\n"
        ]
      end

      msg << ["--#{boundary}--\n"] if !@attachments.empty?

      msg.flatten!
    end

    def create_boundary()
      return "_____clabs_smtp_boundary______#{Time.new.to_i.to_s}___"
    end

    def format_headers
      headers = ["Subject: #{subj}", "From: #{from}", "To: #{to.join(";")}", "Date: #{Time.now.rfc2822}", "MIME-Version: 1.0" ]
      headers << @extra_headers if @extra_headers
      headers.flatten!
      headers.collect! { |hdr| hdr.strip << "\n" }
      [headers].flatten
    end
  end
end

# deprecated - use ClUtil::Smtp instead. The attachments argument is designed
# to be either a single filename or an array of filenames.
def sendmail(to, from, subj, body, smtpsrv=nil, attachments=nil, extra_headers=nil)
  smtpsrv = 'localhost' if !smtpsrv
  smtp = ClUtil::Smtp.new(smtpsrv)
  smtp.to = to
  smtp.from = from
  smtp.subj = subj
  smtp.body = body
  smtp.extra_headers = extra_headers
  attachments = [attachments].flatten
  attachments.compact!
  attachments.each do |attachment_fn|
    smtp.attachments << ClUtil::Attachment.load_from_file(attachment_fn)
  end
  smtp.sendmail
end
