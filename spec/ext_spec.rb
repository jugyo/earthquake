require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ext" do
  it 'should parse 1' do
    text = 'aaa<31>aaaa<1>foo</1>bb<34>bbbb</34>bbb</31>ccc<43>ccccc</43>ccc'.to_esq
    puts text
    text.should == "aaa\e[31maaaa\e[1mfoo\e[0m\e[31mbb\e[34mbbbb\e[0m\e[31mbbb\e[0mccc\e[43mccccc\e[0mccc"
  end

  it 'should parse 2' do
    text = 'aa<34>a<foo>aaa<31>aa</31>aaaa</foo>a</34>aaa'.to_esq
    puts text
    text.should == "aa\e[34ma<foo>aaa\e[31maa\e[0m\e[34maaaa</foo>a\e[0maaa"
  end

  it 'should parse 3' do
    text = 'aa<30>bbbbbbb<32>cccc<90>ddd</90>c</32>b</30>aaa'.to_esq
    puts text
    text.should == "aa\e[30mbbbbbbb\e[32mcccc\e[90mddd\e[0m\e[30m\e[32mc\e[0m\e[30mb\e[0maaa"
  end

  it 'should parse 4' do
    text = 'aa<30><43>bbbbbbb</43><32>cccc<90>ddd</90>c</32>b</30>aaa'.to_esq
    puts text
    text.should == "aa\e[30m\e[43mbbbbbbb\e[0m\e[30m\e[32mcccc\e[90mddd\e[0m\e[30m\e[32mc\e[0m\e[30mb\e[0maaa"
  end
end