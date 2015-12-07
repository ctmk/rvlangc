#! ruby -Ku
# coding: utf-8

=begin
  rvlangcのテストを実行する
=end

require "test/unit"
require "fileutils"

$VERBOSE = nil
begin
  require_relative "./rvlangc"
rescue SystemExit
end

class Rvlangc::Test < Test::Unit::TestCase
  NULL = Object.new
  def NULL.write(s); s.length; end
  
  def setup
    FileUtils.remove_dir('testdata/output') if File.directory?('testdata/output')
  end
  
  def teardown
  end

  # コマンドライン引数のチェック
  def test_argv
    # No options must be error
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run([]) }
    
    # No file specified
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-s']) }
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-o']) }
    
    # Specified a file but output is not specified
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-s', 'testdata/test1.ods']) }
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-s', 'testdata/sub']) }

    # Specified input but output is invalid
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-s', 'testdata/test1.ods', '-o', 'testdata']) }
    assert_raise(Rvlangc::InvalidArgument) { Rvlangc.run(['-s', 'testdata/sub', '-o', 'nowhere']) }
  end

  # ファイルを一つ変換する
  def test_convert_a_file
    FileUtils.mkdir('testdata/output') unless File.directory?('testdata/output')

    assert_nothing_raised() { Rvlangc.run(['-s', 'testdata/test1.ods', '-o', 'testdata/output/test1.dat']) }
    assert(File.exists?('testdata/output/test1.dat'))
    assert(File.exists?('testdata/output/en_us/test1.dat'))

    test1 = Marshal.load(File.open('testdata/output/test1.dat', "rb") {|f| f.read })
    assert_equal("O.K.", test1[:ok])
    assert_equal("決定", test1[:decide])
    assert_equal("保存する", test1[:save])
    assert_equal("読み込む", test1[:load])
    
    test1_en_us = Marshal.load(File.open('testdata/output/en_us/test1.dat', "rb") {|f| f.read })
    assert_equal("O.K.", test1_en_us[:ok])
    assert_equal("Decide", test1_en_us[:decide])
    assert_nil(test1_en_us[:save])
    assert_nil(test1_en_us[:load])
  end

  # ディレクトリごと変換する
  def test_convert_files
    FileUtils.mkdir('testdata/output') unless File.directory?('testdata/output')
    
    assert_nothing_raised() { Rvlangc.run(['-s', 'testdata/sub', '-o', 'testdata/output']) }

    assert(File.exists?('testdata/output/test2.dat'))
    assert(File.exists?('testdata/output/en_us/test2.dat'))
    assert(File.exists?('testdata/output/en_gb/test2.dat'))
    assert(File.exists?('testdata/output/la/test2.dat'))
    
    assert(File.exists?('testdata/output/test3.dat'))
    assert(File.exists?('testdata/output/en_us/test3.dat'))
    assert(File.exists?('testdata/output/fr_fr/test3.dat'))
    assert(File.exists?('testdata/output/la/test3.dat'))

    test2 = Marshal.load(File.open('testdata/output/test2.dat', "rb") {|f| f.read })
    assert_equal("秋", test2[:autumn])
    assert_equal("共同住宅", test2[:apart])
    test2_en_us = Marshal.load(File.open('testdata/output/en_us/test2.dat', "rb") {|f| f.read })
    assert_equal("Fall", test2_en_us[:autumn])
    assert_equal("Apartment", test2_en_us[:apart])
    test2_en_gb = Marshal.load(File.open('testdata/output/en_gb/test2.dat', "rb") {|f| f.read })
    assert_equal("Autumn", test2_en_gb[:autumn])
    assert_equal("Flat", test2_en_gb[:apart])
    test2_la = Marshal.load(File.open('testdata/output/la/test2.dat', "rb") {|f| f.read })
    assert_equal("Autumnus", test2_la[:autumn])
    assert_equal("Insula", test2_la[:apart])

    test3 = Marshal.load(File.open('testdata/output/test3.dat', "rb") {|f| f.read })
    assert_equal("夏", test3[:summer])
    assert_equal("賽は投げられた", test3[:iae])
    test3_en_us = Marshal.load(File.open('testdata/output/en_us/test3.dat', "rb") {|f| f.read })
    assert_equal("Summer",test3_en_us[:summer])
    assert_equal("The die is cast", test3_en_us[:iae])
    test3_fr_fr = Marshal.load(File.open('testdata/output/fr_fr/test3.dat', "rb") {|f| f.read })
    assert_equal("Été", test3_fr_fr[:summer])
    assert_equal("Le sort en est jeté", test3_fr_fr[:iae])
    test3_la = Marshal.load(File.open('testdata/output/la/test3.dat', "rb") {|f| f.read })
    assert_equal("Aestas", test3_la[:summer])
    assert_equal("Iacta alea est", test3_la[:iae])
  end

  # 変換するファイルに問題があった場合
  def test_convert_invalid_data
    assert_raise(Rvlangc::Converter::InvalidIdError) {
      Rvlangc.run(['-s', 'testdata/test_invalid_id.ods', '-o', 'testdata/dummy.dat'])
    }
    assert_raise(Rvlangc::Converter::InvalidIdError) {
      Rvlangc.run(['-s', 'testdata/test_id_duplicated.ods', '-o', 'testdata/dummy.dat'])
    }
  end

end

