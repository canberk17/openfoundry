import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Button, Card } from '@nextui-org/react';
import io from 'socket.io-client';
import styles from '../styles/Analyzer.module.css';

const socket = io('http://127.0.0.1:5000');

const Typewriter = ({ text, delay }) => {
  const [currentText, setCurrentText] = useState('');
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    if (currentIndex < text.length) {
      const timeout = setTimeout(() => {
        setCurrentText(prevText => prevText + text.charAt(currentIndex));
        setCurrentIndex(prevIndex => prevIndex + 1);
      }, delay);

      return () => clearTimeout(timeout);
    }
  }, [currentIndex, delay, text]);

  return <span>{currentText}</span>;
};

const CodeQueryForm = () => {
  const [question, setQuestion] = useState('');
  const [code, setCode] = useState('');
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    socket.on('log', data => {
      const newLog = <Typewriter key={Date.now()} text={data.data + '\n'} delay={10} />;
      setLogs(prevLogs => [...prevLogs, newLog]);
    });

    return () => {
      socket.off('log');
    };
  }, []);

  const handleSubmit = async () => {
    setLogs([]);
    try {
      await axios.post('http://127.0.0.1:5000/analyze', {
        question,
        source_code: code
      }, {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error:', error);
      const errorLog = <Typewriter key={Date.now()} text='An error occurred while processing your request.\n' delay={10} />;
      setLogs([errorLog]);
    }
  };

  return (
    <div className={styles.container}>
      <Card className={styles.card}>
        <input
          type="text"
          placeholder="Ask your question"
          className={styles.searchBar}
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
        />
        <textarea
          placeholder="Enter your Solidity code here"
          className={styles.codeEditor}
          value={code}
          onChange={(e) => setCode(e.target.value)}
        />
        <Button
          className={styles.button}
          color="gradient"
          onClick={handleSubmit}
        >
          Analyze
        </Button>
      </Card>
      <Card className={styles.responseCard}>
        <pre className={styles.response}>
          {logs}
        </pre>
      </Card>
    </div>
  );
};

export default CodeQueryForm;