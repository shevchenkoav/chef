#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'chef/dsl/data_query'

class DataQueryDSLTester
  include Chef::DSL::DataQuery
end

describe Chef::DSL::DataQuery do
  let(:node) { Hash.new }

  let(:language) do
    language = DataQueryDSLTester.new
    language.stub(:node).and_return(@node)
    language
  end

  describe "::data_bag" do
    it "lists the items in a data bag" do
      allow(Chef::DataBag).to receive(:load)
        .with("bag_name")
        .and_return("item_1" => "http://url_for/item_1", "item_2" => "http://url_for/item_2")
      expect( language.data_bag("bag_name").sort ).to eql %w(item_1 item_2)
    end
  end

  shared_examples_for "a data bag item" do
    it "validates the name of the data bag you're trying to load an item from" do
      expect{ language.send(method_name, " %%^& ", "item_name") }.to raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "validates the id of the data bag item you're trying to load" do
      expect{ language.send(method_name, "bag_name", " 987 (*&()") }.to raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

    it "validates that the id of the data bag item is not nil" do
      expect{ language.send(method_name, "bag_name", nil) }.to raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end
  end

  describe "::data_bag_item" do
    let(:bag_name) { "bag_name" }

    let(:item_name) { "item_name" }

    let(:raw_data) {{
      "id" => item_name,
      "greeting" => "hello",
      "nested" => {
        "a1" => [1, 2, 3],
        "a2" => { "b1" => true }
      }
    }}

    let(:item) do
      item = Chef::DataBagItem.new
      item.data_bag(bag_name)
      item.raw_data = raw_data
      item
    end

    it "fetches a data bag item" do
      allow( Chef::DataBagItem ).to receive(:load).with(bag_name, item_name).and_return(item)
      expect( language.data_bag_item(bag_name, item_name) ).to eql item
    end

    include_examples "a data bag item" do
      let(:method_name) { :data_bag_item }
    end

    context "when the item is encrypted" do

      let(:secret) { "abc123SECRET" }

      let(:encoded_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_data, secret) }

      let(:item) do
        item = Chef::DataBagItem.new
        item.data_bag(bag_name)
        item.raw_data = encoded_data
        item
      end

      it "detects v1 encrypted data bag items" do
        Chef::Config[:data_bag_encrypt_version] = 1
      end

      it "detects v2 encrypted data bag items" do
        Chef::Config[:data_bag_encrypt_version] = 2
      end

      it "detects v3 encrypted data bag items" do
        Chef::Config[:data_bag_encrypt_version] = 3
      end

      shared_examples_for "an encrypted data bag item" do
        it "returns an encrypted data bag item" do

        end
      end

      context "when a secret is supplied" do
        include_examples "an encrypted data bag item" do

        end
      end

      context "when a secret is not supplied" do
        context "when a secret is located at Chef::Config[:encrypted_data_bag_secret]" do
          include_examples "an encrypted data bag item" do

          end
        end

        context "when a secret is not located at Chef::Config[:encrypted_data_bag_secret]" do
          it "should fail to load the data bag item" do

          end
        end
      end
    end
  end
end
