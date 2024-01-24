require 'stackify-api-ruby'
require_relative '../helpers/dummy_logger'
require_relative '../helpers/dummy_logger_client'
require 'logger'

RSpec.describe ::Stackify::LoggerProxy do
  let(:proxy_logger) { DummyLogger.new() }
  let(:stackify_logger) { instance_double(DummyLoggerClient) }

  before do
    allow(stackify_logger).to receive(:log)
    allow(::Stackify).to receive(:logger_client).and_return(stackify_logger)
    allow(proxy_logger).to receive(:level).and_return(Logger::INFO)
  end

  subject { described_class.new(proxy_logger) }

  describe '#initialize' do
    it 'sets up the logger methods' do
      expect(subject).to respond_to(:debug)
      expect(subject).to respond_to(:info)
      expect(subject).to respond_to(:warn)
      expect(subject).to respond_to(:error)
      expect(subject).to respond_to(:fatal)
      expect(subject).to respond_to(:unknown)
    end
  end

  describe 'log forwarding' do
    it 'forwards log calls to Stackify and original logger' do
      message = 'Test log message'

      expect(Stackify.logger_client).to receive(:log).with(Logger::INFO, 'debug', message, any_args).once
      expect(proxy_logger).to receive(:debug).with(message).once

      subject.debug(message)
    end
  end

  # Add more test cases for other log levels and scenarios
  describe 'method_missing and respond_to_missing?' do
    it 'forwards undefined methods to the original logger' do
      # since broadcast_to is available only on the DummyLogger
      expect(proxy_logger).to receive(:broadcast_to).with('arg1', 'arg2').once
      subject.broadcast_to('arg1', 'arg2')
    end

    it 'correctly responds to defined and undefined methods' do
        expect(subject).to respond_to(:broadcast_to)
    end
  end
end